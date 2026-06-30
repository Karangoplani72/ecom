import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/data/services/admin_name_resolver.dart';
import 'package:ecom/features/admin/data/services/csv_export_helper.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────
// Feature 1: Summary metrics provider
// Reads the payouts collection once (via stream so it stays live)
// and reduces it down to the four headline numbers shown above the
// filters. Kept separate from the main settlements stream so a
// failure here never takes down the list itself. Declared as a plain
// StreamProvider (matching e.g. platformConfigProvider in
// admin_controller.dart) rather than a @riverpod-generated provider,
// so this single file has no codegen / build_runner dependency.
// ─────────────────────────────────────────────────────────────
final adminSettlementMetricsProvider = StreamProvider<Map<String, dynamic>>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore
      .collection('payouts')
      .snapshots()
      .map<Map<String, dynamic>>((snapshot) {
        double totalPending = 0;
        double totalPaidThisMonth = 0;
        int pendingCount = 0;
        int completedWithDurationCount = 0;
        Duration durationSum = Duration.zero;

        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final status = data['status'] as String? ?? 'pending';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

          if (status == 'pending') {
            totalPending += amount;
            pendingCount++;
          }

          if (status == 'completed') {
            final processedAt = (data['processedAt'] as Timestamp?)?.toDate();
            if (processedAt != null && !processedAt.isBefore(monthStart)) {
              totalPaidThisMonth += amount;
            }

            final requestedAt = (data['requestedAt'] as Timestamp?)?.toDate();
            if (requestedAt != null && processedAt != null) {
              durationSum += processedAt.difference(requestedAt);
              completedWithDurationCount++;
            }
          }
        }

        final avgProcessingDays = completedWithDurationCount > 0
            ? durationSum.inHours / 24 / completedWithDurationCount
            : 0.0;

        return <String, dynamic>{
          'totalPending': totalPending,
          'totalPaidThisMonth': totalPaidThisMonth,
          'pendingCount': pendingCount,
          'avgProcessingDays': avgProcessingDays,
        };
      })
      .handleError(
        (error, stackTrace) => <String, dynamic>{
          'totalPending': 0.0,
          'totalPaidThisMonth': 0.0,
          'pendingCount': 0,
          'avgProcessingDays': 0.0,
        },
      );
});

// ─────────────────────────────────────────────────────────────
// Unsettled wallet balances — gives admin visibility into money
// owed to sellers BEFORE they request a withdrawal (the `payouts`
// collection above only reflects requests sellers have already
// made). Reads `wallets` directly, live.
//
// wallet.balance              = available, ready for seller to withdraw
// wallet.pendingEscrowBalance = held in escrow, not yet released
//   (released automatically when the order is marked Delivered, or
//   after the 10-day escrow hold matures — see Cloud Functions
//   `onOrderStatusUpdate` / `scheduledEscrowRelease`)
// ─────────────────────────────────────────────────────────────
class UnsettledWallet {
  final String storeId;
  final double balance;
  final double pendingEscrowBalance;

  const UnsettledWallet({
    required this.storeId,
    required this.balance,
    required this.pendingEscrowBalance,
  });

  double get total => balance + pendingEscrowBalance;
}

final adminUnsettledWalletsProvider = StreamProvider<List<UnsettledWallet>>((
  ref,
) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore
      .collection('wallets')
      .snapshots()
      .map((snapshot) {
        final wallets = snapshot.docs
            .map((doc) {
              final data = doc.data();
              return UnsettledWallet(
                storeId: data['storeId'] as String? ?? doc.id,
                balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
                pendingEscrowBalance:
                    (data['pendingEscrowBalance'] as num?)?.toDouble() ?? 0.0,
              );
            })
            .where((w) => w.total > 0)
            .toList();
        wallets.sort((a, b) => b.total.compareTo(a.total));
        return wallets;
      })
      .handleError((error, stackTrace) => <UnsettledWallet>[]);
});

class _UnsettledBalancesSection extends ConsumerWidget {
  final NumberFormat currencyFmt;

  const _UnsettledBalancesSection({required this.currencyFmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(adminUnsettledWalletsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return walletsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (wallets) {
        if (wallets.isEmpty) return const SizedBox.shrink();

        final totalAvailable = wallets.fold<double>(0, (s, w) => s + w.balance);
        final totalEscrow = wallets.fold<double>(
          0,
          (s, w) => s + w.pendingEscrowBalance,
        );

        final readyWallets = wallets.where((w) => w.balance > 0).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: AdminSectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Unsettled Seller Balances',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${currencyFmt.format(totalAvailable)} ready • '
                      '${currencyFmt.format(totalEscrow)} in escrow',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white54
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance owed to sellers that have not yet requested a '
                  'payout. "Ready" can be withdrawn now; "in escrow" '
                  'releases automatically on delivery or after the 10-day '
                  'hold.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white38
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ...readyWallets
                    .take(5)
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ResolvedStoreName(storeId: w.storeId),
                            ),
                            if (w.balance > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: AdminStatusPill(
                                  label:
                                      'Ready: ${currencyFmt.format(w.balance)}',
                                  color: AppColors.success,
                                ),
                              ),
                            if (w.pendingEscrowBalance > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: AdminStatusPill(
                                  label:
                                      'Escrow: ${currencyFmt.format(w.pendingEscrowBalance)}',
                                  color: AppColors.warning,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                if (readyWallets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No sellers with ready balances.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white54
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                if (readyWallets.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '+${readyWallets.length - 5} more stores',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResolvedStoreName extends ConsumerWidget {
  final String storeId;

  const _ResolvedStoreName({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: ref
          .read(adminNameResolverProvider.notifier)
          .resolveStoreName(storeId),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? storeId,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class AdminSettlementsScreen extends ConsumerStatefulWidget {
  const AdminSettlementsScreen({super.key});

  @override
  ConsumerState<AdminSettlementsScreen> createState() =>
      _AdminSettlementsScreenState();
}

class _AdminSettlementsScreenState
    extends ConsumerState<AdminSettlementsScreen> {
  String _statusFilter = 'all'; // all, pending, processed, rejected
  String _dateFilter = 'all'; // all, week, month
  bool _isExporting = false;
  bool _isReleasingEscrows = false;

  // Feature 5: search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Feature 3: bulk selection
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  // Cache of the latest stream snapshot's docs, keyed by id, so the bulk
  // action can know each selected settlement's current status without an
  // extra read.
  Map<String, Map<String, dynamic>> _docCache = {};

  // Feature 5: local cache of resolved store names (sellerId -> name), used
  // so the search box can match on store name even though name resolution
  // is async. Populated as tiles resolve their names; triggers a rebuild
  // once a new name arrives so a pending search re-filters correctly.
  final Map<String, String> _resolvedNames = {};

  @override
  void initState() {
    super.initState();
    // Trigger escrow release when admin opens this screen so any matured
    // escrows are released and sellers can request payouts.
    _triggerEscrowRelease(silent: true);
  }

  /// Calls the releaseMaturedEscrows Cloud Function to release any
  /// escrows whose 10-day hold has expired.
  Future<void> _triggerEscrowRelease({bool silent = false}) async {
    if (_isReleasingEscrows) return;
    setState(() => _isReleasingEscrows = true);

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
        }
        return;
      }

      final response = await http
          .post(
            Uri.parse('https://releasematuredescrows-oshbhnscba-uc.a.run.app'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (!silent && mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Escrow release completed'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Escrow release failed: ${response.statusCode}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Escrow release failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isReleasingEscrows = false);
    }
  }

  void _onStoreNameResolved(String sellerId, String name) {
    if (_resolvedNames[sellerId] == name) return;
    _resolvedNames[sellerId] = name;
    if (_searchQuery.isNotEmpty && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _enterSelectionMode(String docId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(docId);
    });
  }

  void _toggleSelected(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _exportSettlements(FirebaseFirestore firestore) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final snapshot = await firestore.collection('payouts').get();
      final nameResolver = ref.read(adminNameResolverProvider.notifier);
      final rows = <List<dynamic>>[
        ['Settlements Export'],
        ['Export Date', DateTime.now().toIso8601String()],
        [],
        [
          'Settlement ID',
          'Seller ID',
          'Seller Store Name',
          'Amount',
          'Status',
          'Date',
        ],
      ];

      var docs = snapshot.docs;

      // Filter by status in memory
      if (_statusFilter != 'all') {
        docs = docs.where((doc) {
          final data = doc.data();
          return data['status'] == _statusFilter;
        }).toList();
      }

      // Filter by date in memory
      if (_dateFilter != 'all') {
        final now = DateTime.now();
        final limitDate = _dateFilter == 'week'
            ? now.subtract(const Duration(days: 7))
            : now.subtract(const Duration(days: 30));
        docs = docs.where((doc) {
          final data = doc.data();
          final dateVal =
              (data['requestedAt'] as Timestamp? ??
                      data['createdAt'] as Timestamp?)
                  ?.toDate();
          return dateVal != null && dateVal.isAfter(limitDate);
        }).toList();
      }

      // Sort by requestedAt descending in memory
      docs.sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();
        final dateA =
            (dataA['requestedAt'] as Timestamp? ??
                    dataA['createdAt'] as Timestamp?)
                ?.toDate() ??
            DateTime(1970);
        final dateB =
            (dataB['requestedAt'] as Timestamp? ??
                    dataB['createdAt'] as Timestamp?)
                ?.toDate() ??
            DateTime(1970);
        return dateB.compareTo(dateA);
      });

      for (final doc in docs) {
        final data = doc.data();
        final sellerId =
            data['sellerId'] as String? ?? data['storeId'] as String? ?? '';
        final storeName = await nameResolver.resolveStoreName(sellerId);

        final createdAtTimestamp =
            data['requestedAt'] as Timestamp? ??
            data['createdAt'] as Timestamp?;
        final dateStr = createdAtTimestamp != null
            ? createdAtTimestamp.toDate().toIso8601String()
            : 'Unknown';

        rows.add([
          doc.id,
          sellerId,
          storeName,
          (data['amount'] as num?)?.toDouble() ?? 0.0,
          data['status'] ?? '',
          dateStr,
        ]);
      }

      await CsvExportHelper.exportToCsv(
        fileName: 'settlements_export.csv',
        rows: rows,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settlements exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  // Feature 3: bulk process selected pending settlements
  Future<void> _bulkProcessSelected() async {
    final idsToProcess = _selectedIds.where((id) {
      final data = _docCache[id];
      return data != null &&
          (data['status'] as String? ?? 'pending') == 'pending';
    }).toList();

    if (idsToProcess.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending settlements in the current selection'),
        ),
      );
      _exitSelectionMode();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulk Process Settlements'),
        content: Text(
          'Mark ${idsToProcess.length} pending settlement(s) as processing? '
          'Completed/failed/already-processing items in the selection will be skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Process All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    int successCount = 0;
    int failCount = 0;
    final notifier = ref.read(adminControllerProvider.notifier);

    // Progress dialog with a live counter.
    int completedSoFar = 0;
    final progressNotifier = ValueNotifier<int>(0);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ValueListenableBuilder<int>(
        valueListenable: progressNotifier,
        builder: (ctx, value, _) => AlertDialog(
          title: const Text('Processing Settlements'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(value: value / idsToProcess.length),
              const SizedBox(height: 16),
              Text('Processed $value of ${idsToProcess.length}'),
            ],
          ),
        ),
      ),
    );

    for (final id in idsToProcess) {
      final result = await notifier.processSettlement(id);
      result.fold((_) => failCount++, (_) => successCount++);
      completedSoFar++;
      progressNotifier.value = completedSoFar;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close progress dialog
    _exitSelectionMode();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failCount == 0
              ? 'Processed $successCount settlement(s) successfully'
              : 'Processed $successCount, failed $failCount',
        ),
        backgroundColor: failCount == 0 ? AppColors.success : AppColors.warning,
      ),
    );
  }

  bool _matchesSearch(String docId, String sellerId) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    if (docId.toLowerCase().startsWith(q)) return true;
    if (sellerId.toLowerCase().contains(q)) return true;
    final storeName = _resolvedNames[sellerId];
    if (storeName != null && storeName.toLowerCase().contains(q)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('d MMM yyyy');

    // Query payouts basic stream without sorting/filtering clauses to prevent index failures
    final settlementsQuery = firestore.collection('payouts');

    return AdminScaffold(
      title: 'Seller Settlements',
      subtitle: 'Manage seller payouts and settlements',
      actions: [
        _isReleasingEscrows
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.lock_open_rounded),
                tooltip: 'Release Matured Escrows',
                onPressed: () => _triggerEscrowRelease(silent: false),
              ),
        _isExporting
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Export CSV',
                onPressed: () => _exportSettlements(firestore),
              ),
      ],
      floatingActionButton: _selectionMode && _selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _bulkProcessSelected,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.done_all_rounded),
              label: Text('Process ${_selectedIds.length} selected'),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // Live wallet balances owed to sellers, before any payout request
          SliverToBoxAdapter(
            child: _UnsettledBalancesSection(currencyFmt: currencyFmt),
          ),
          SliverToBoxAdapter(
            child: _EarlyReleaseRequestsSection(currencyFmt: currencyFmt),
          ),
          // Feature 1: Summary metrics row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SettlementMetricsRow(currencyFmt: currencyFmt),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          // Filters + search
          SliverToBoxAdapter(
            child: Container(
              color: isDark
                  ? AppColors.darkBgSurface
                  : AppColors.lightBgSurface,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                children: [
                  // Feature 5: search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by store name or settlement ID...',
                      hintStyle: GoogleFonts.inter(fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBgPrimary
                          : AppColors.lightBgPrimary,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in [
                          ('all', 'All'),
                          ('pending', 'Pending'),
                          ('processing', 'Processing'),
                          ('completed', 'Completed'),
                          ('failed', 'Failed'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f.$2),
                              selected: _statusFilter == f.$1,
                              onSelected: (_) =>
                                  setState(() => _statusFilter = f.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in [
                          ('all', 'All Time'),
                          ('week', 'Last 7 Days'),
                          ('month', 'Last 30 Days'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f.$2),
                              selected: _dateFilter == f.$1,
                              onSelected: (_) =>
                                  setState(() => _dateFilter = f.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selectionMode) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.check_box_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_selectedIds.length} selected',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _exitSelectionMode,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Settlements List
          ),
          StreamBuilder<QuerySnapshot>(
            stream: settlementsQuery.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: AdminEmptyRow(
                    icon: Icons.error_outline,
                    message: snapshot.error.toString(),
                  ),
                );
              }

              var settlements = snapshot.data?.docs ?? [];

              // 1. Filter by status in memory
              if (_statusFilter != 'all') {
                settlements = settlements.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == _statusFilter;
                }).toList();
              }

              // 2. Filter by date in memory
              if (_dateFilter != 'all') {
                final now = DateTime.now();
                final limitDate = _dateFilter == 'week'
                    ? now.subtract(const Duration(days: 7))
                    : now.subtract(const Duration(days: 30));
                settlements = settlements.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dateVal =
                      (data['requestedAt'] as Timestamp? ??
                              data['createdAt'] as Timestamp?)
                          ?.toDate();
                  return dateVal != null && dateVal.isAfter(limitDate);
                }).toList();
              }

              // 3. Sort by requestedAt descending in memory
              settlements.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final dateA =
                    (dataA['requestedAt'] as Timestamp? ??
                            dataA['createdAt'] as Timestamp?)
                        ?.toDate() ??
                    DateTime(1970);
                final dateB =
                    (dataB['requestedAt'] as Timestamp? ??
                            dataB['createdAt'] as Timestamp?)
                        ?.toDate() ??
                    DateTime(1970);
                return dateB.compareTo(dateA);
              });

              // Update doc cache for bulk actions to reference current statuses.
              _docCache = {
                for (final doc in settlements)
                  doc.id: doc.data() as Map<String, dynamic>,
              };

              // Feature 5: search filter. Matches on settlement ID prefix
              // or seller ID directly (synchronous), and on store name via
              // the locally cached resolved names (async, populated by
              // each tile's FutureBuilder as it resolves — see
              // _onStoreNameResolved). Kick off resolution for any
              // currently-unresolved seller in the visible set so the
              // cache fills in even before its tile has rendered.
              if (_searchQuery.isNotEmpty) {
                for (final doc in settlements) {
                  final data = doc.data() as Map<String, dynamic>;
                  final sellerId =
                      data['sellerId'] as String? ??
                      data['storeId'] as String? ??
                      '';
                  if (sellerId.isNotEmpty &&
                      !_resolvedNames.containsKey(sellerId)) {
                    ref
                        .read(adminNameResolverProvider.notifier)
                        .resolveStoreName(sellerId)
                        .then((name) => _onStoreNameResolved(sellerId, name));
                  }
                }
                settlements = settlements.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final sellerId =
                      data['sellerId'] as String? ??
                      data['storeId'] as String? ??
                      '';
                  return _matchesSearch(doc.id, sellerId);
                }).toList();
              }

              if (settlements.isEmpty) {
                return SliverFillRemaining(
                  child: AdminEmptyRow(
                    icon: Icons.account_balance_wallet_outlined,
                    message: _searchQuery.isNotEmpty
                        ? 'No settlements match "$_searchQuery"'
                        : 'No settlements found',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                sliver: SliverList.separated(
                  itemCount: settlements.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _SettlementTile(
                    settlement: settlements[i].data() as Map<String, dynamic>,
                    docId: settlements[i].id,
                    currencyFmt: currencyFmt,
                    dateFmt: dateFmt,
                    selectionMode: _selectionMode,
                    isSelected: _selectedIds.contains(settlements[i].id),
                    onEnterSelectionMode: () =>
                        _enterSelectionMode(settlements[i].id),
                    onToggleSelected: () => _toggleSelected(settlements[i].id),
                    onStoreNameResolved: _onStoreNameResolved,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Feature 1: Summary metrics row
// ─────────────────────────────────────────────────────────────
class _SettlementMetricsRow extends ConsumerWidget {
  final NumberFormat currencyFmt;

  const _SettlementMetricsRow({required this.currencyFmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminSettlementMetricsProvider);

    return metricsAsync.when(
      data: (metrics) {
        final totalPending =
            (metrics['totalPending'] as num?)?.toDouble() ?? 0.0;
        final totalPaidThisMonth =
            (metrics['totalPaidThisMonth'] as num?)?.toDouble() ?? 0.0;
        final pendingCount = (metrics['pendingCount'] as num?)?.toInt() ?? 0;
        final avgDays =
            (metrics['avgProcessingDays'] as num?)?.toDouble() ?? 0.0;

        return AdminMetricGrid(
          metrics: [
            AdminMetricCard(
              label: 'Total Pending Amount',
              value: currencyFmt.format(totalPending),
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
            ),
            AdminMetricCard(
              label: 'Paid Out This Month',
              value: currencyFmt.format(totalPaidThisMonth),
              icon: Icons.account_balance_wallet_rounded,
              color: AppColors.success,
            ),
            AdminMetricCard(
              label: 'Pending Requests',
              value: '$pendingCount',
              icon: Icons.pending_actions_rounded,
              color: AppColors.info,
            ),
            AdminMetricCard(
              label: 'Avg. Processing Time',
              value: avgDays > 0 ? '${avgDays.toStringAsFixed(1)}d' : '—',
              icon: Icons.timer_outlined,
              color: AppColors.primary,
            ),
          ],
        );
      },
      loading: () => AdminMetricGrid(
        metrics: [
          AdminMetricCard(
            label: 'Total Pending Amount',
            value: '—',
            icon: Icons.hourglass_top_rounded,
            color: AppColors.warning,
          ),
          AdminMetricCard(
            label: 'Paid Out This Month',
            value: '—',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.success,
          ),
          AdminMetricCard(
            label: 'Pending Requests',
            value: '—',
            icon: Icons.pending_actions_rounded,
            color: AppColors.info,
          ),
          AdminMetricCard(
            label: 'Avg. Processing Time',
            value: '—',
            icon: Icons.timer_outlined,
            color: AppColors.primary,
          ),
        ],
      ),
      // Metrics must never crash the screen — show grey dashes instead.
      error: (error, stack) => AdminMetricGrid(
        metrics: [
          AdminMetricCard(
            label: 'Total Pending Amount',
            value: '—',
            icon: Icons.hourglass_top_rounded,
            color: Colors.grey,
          ),
          AdminMetricCard(
            label: 'Paid Out This Month',
            value: '—',
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.grey,
          ),
          AdminMetricCard(
            label: 'Pending Requests',
            value: '—',
            icon: Icons.pending_actions_rounded,
            color: Colors.grey,
          ),
          AdminMetricCard(
            label: 'Avg. Processing Time',
            value: '—',
            icon: Icons.timer_outlined,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Settlement tile — existing layout, extended with:
// Feature 2 (bank-detail expansion), Feature 3 (multi-select),
// Feature 4 (detail bottom sheet on body tap)
// ─────────────────────────────────────────────────────────────
class _SettlementTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> settlement;
  final String docId;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onEnterSelectionMode;
  final VoidCallback onToggleSelected;
  final void Function(String sellerId, String name) onStoreNameResolved;

  const _SettlementTile({
    required this.settlement,
    required this.docId,
    required this.currencyFmt,
    required this.dateFmt,
    required this.selectionMode,
    required this.isSelected,
    required this.onEnterSelectionMode,
    required this.onToggleSelected,
    required this.onStoreNameResolved,
  });

  @override
  ConsumerState<_SettlementTile> createState() => _SettlementTileState();
}

class _SettlementTileState extends ConsumerState<_SettlementTile> {
  bool _bankDetailsExpanded = false;
  late Future<String> _storeNameFuture;

  String get _sellerId =>
      widget.settlement['sellerId'] as String? ??
      widget.settlement['storeId'] as String? ??
      'Unknown';

  @override
  void initState() {
    super.initState();
    _storeNameFuture = ref
        .read(adminNameResolverProvider.notifier)
        .resolveStoreName(_sellerId);
    _storeNameFuture.then((name) {
      // Reported asynchronously, never during this widget's own build.
      widget.onStoreNameResolved(_sellerId, name);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'processing':
        return const Color(0xFF2563EB);
      case 'completed':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settlement = widget.settlement;
    final docId = widget.docId;
    final status = settlement['status'] as String? ?? 'pending';
    final amount = (settlement['amount'] as num?)?.toDouble() ?? 0;
    final sellerId = _sellerId;
    final dateVal =
        settlement['requestedAt'] as Timestamp? ??
        settlement['createdAt'] as Timestamp?;
    final statusColor = _statusColor(status);
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecond
        : AppColors.lightTextSecond;

    return AdminSectionCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.selectionMode
            ? widget.onToggleSelected
            : () => _showSettlementDetailSheet(
                context,
                ref,
                settlement,
                docId,
                widget.currencyFmt,
                widget.dateFmt,
              ),
        onLongPress: widget.selectionMode ? null : widget.onEnterSelectionMode,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (widget.selectionMode) ...[
                        Checkbox(
                          value: widget.isSelected,
                          onChanged: (_) => widget.onToggleSelected(),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'Settlement #${docId.substring(0, docId.length >= 8 ? 8 : docId.length).toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  AdminStatusPill(
                    label: status.toUpperCase(),
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: FutureBuilder<String>(
                      future: _storeNameFuture,
                      builder: (context, snapshot) {
                        final name = snapshot.data ?? 'Loading...';
                        return Text(
                          'Seller Store: $name',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  Text(
                    widget.currencyFmt.format(amount),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created: ${dateVal != null ? widget.dateFmt.format(dateVal.toDate()) : 'Unknown'}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 4),
              // Feature 2: expandable bank-details section
              InkWell(
                onTap: () => setState(
                  () => _bankDetailsExpanded = !_bankDetailsExpanded,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _bankDetailsExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _bankDetailsExpanded
                            ? 'Hide bank details'
                            : 'View bank details',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_bankDetailsExpanded)
                _BankDetailsSection(sellerId: sellerId, isDark: isDark),
              const SizedBox(height: 8),
              if (!widget.selectionMode) ...[
                if (status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Process'),
                          onPressed: () =>
                              _processSettlement(context, ref, docId),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          onPressed: () =>
                              _rejectSettlement(context, ref, docId),
                        ),
                      ),
                    ],
                  )
                else if (status == 'processing')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.done_all_rounded, size: 16),
                          label: const Text('Complete Payout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                          ),
                          onPressed: () =>
                              _completeSettlement(context, ref, docId),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          onPressed: () =>
                              _rejectSettlement(context, ref, docId),
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Feature 6: Process now opens an internal-note dialog first, then calls
  // the existing controller method, then attaches the note as a follow-up
  // Firestore update (per the spec: use .update(), not the repo method).
  Future<void> _processSettlement(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    final note = await _showAdminNoteDialog(
      context,
      title: 'Process Settlement',
    );
    if (note == null) return; // dialog cancelled

    final result = await ref
        .read(adminControllerProvider.notifier)
        .processSettlement(settlementId);

    if (note.trim().isNotEmpty) {
      await _saveAdminNote(ref, settlementId, note.trim());
    }

    if (!context.mounted) return;
    result.fold(
      (err) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settlement marked for processing')),
      ),
    );
  }

  Future<void> _completeSettlement(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Payout'),
        content: const Text(
          'Are you sure you want to mark this payout as completed? This will deduct the amount from the merchant\'s wallet balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final note = await _showAdminNoteDialog(context, title: 'Complete Payout');
    if (note == null) return; // dialog cancelled

    final result = await ref
        .read(adminControllerProvider.notifier)
        .completeSettlement(settlementId);

    if (note.trim().isNotEmpty) {
      await _saveAdminNote(ref, settlementId, note.trim());
    }

    if (!context.mounted) return;
    result.fold(
      (err) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settlement completed successfully')),
      ),
    );
  }

  Future<void> _rejectSettlement(
    BuildContext context,
    WidgetRef ref,
    String settlementId,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Settlement'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) return;

    final result = await ref
        .read(adminControllerProvider.notifier)
        .rejectSettlement(settlementId, reasonController.text.trim());

    if (!context.mounted) return;
    result.fold(
      (err) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err))),
      (_) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settlement rejected'))),
    );
  }
}

// Feature 6: internal note dialog shared by Process / Complete actions.
// Returns null if cancelled, otherwise the (possibly empty) note text.
Future<String?> _showAdminNoteDialog(
  BuildContext context, {
  required String title,
}) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optional internal note for this action (visible to admins only):',
            style: GoogleFonts.inter(fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. verified with seller over call...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}

Future<void> _saveAdminNote(
  WidgetRef ref,
  String settlementId,
  String note,
) async {
  try {
    final firestore = ref.read(firebaseFirestoreProvider);
    await firestore.collection('payouts').doc(settlementId).update({
      'adminNote': note,
    });
  } catch (_) {
    // Non-critical — the settlement action itself already succeeded/failed
    // independently, so a note-save failure is swallowed rather than
    // surfaced as a blocking error.
  }
}

// ─────────────────────────────────────────────────────────────
// Feature 2: bank details section, fetched lazily on expand
// ─────────────────────────────────────────────────────────────
class _BankDetailsSection extends ConsumerStatefulWidget {
  final String sellerId;
  final bool isDark;

  const _BankDetailsSection({required this.sellerId, required this.isDark});

  @override
  ConsumerState<_BankDetailsSection> createState() =>
      _BankDetailsSectionState();
}

class _BankDetailsSectionState extends ConsumerState<_BankDetailsSection> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _bankDetailsFuture;

  @override
  void initState() {
    super.initState();
    // Fetched once when this section first mounts (i.e. the first time the
    // tile is expanded) rather than on every rebuild of the parent tile —
    // the parent rebuilds whenever the live `payouts` stream emits, which
    // would otherwise re-fire this read on every unrelated Firestore update.
    _bankDetailsFuture = ref
        .read(firebaseFirestoreProvider)
        .collection('sellers')
        .doc(widget.sellerId)
        .collection('bankDetails')
        .doc('primary')
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final secondaryTextColor = widget.isDark
        ? AppColors.darkTextSecond
        : AppColors.lightTextSecond;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _bankDetailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !(snapshot.data?.exists ?? false)) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Bank details not available',
              style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor),
            ),
          );
        }

        final data = snapshot.data!.data() ?? {};
        final holderName = data['holderName'] as String? ?? '—';
        final bankName = data['bankName'] as String? ?? '—';
        final maskedAccountNumber =
            data['maskedAccountNumber'] as String? ?? '—';
        final ifsc = data['ifsc'] as String? ?? '—';
        final branch = data['branch'] as String? ?? '—';

        return Container(
          margin: const EdgeInsets.only(top: 4, bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDark
                ? AppColors.darkBgPrimary
                : AppColors.lightBgPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bankDetailRow('Account Holder', holderName, secondaryTextColor),
              _bankDetailRow('Bank Name', bankName, secondaryTextColor),
              _bankDetailRow(
                'Masked Account No.',
                maskedAccountNumber,
                secondaryTextColor,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _bankDetailRow('IFSC', ifsc, secondaryTextColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: 'Copy IFSC',
                    onPressed: ifsc == '—'
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: ifsc));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('IFSC copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              _bankDetailRow('Branch', branch, secondaryTextColor),
            ],
          ),
        );
      },
    );
  }

  Widget _bankDetailRow(String label, String value, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: secondaryTextColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Feature 4: settlement detail bottom sheet
// ─────────────────────────────────────────────────────────────
void _showSettlementDetailSheet(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> settlement,
  String docId,
  NumberFormat currencyFmt,
  DateFormat dateFmt,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SettlementDetailSheet(
      settlement: settlement,
      docId: docId,
      currencyFmt: currencyFmt,
      dateFmt: dateFmt,
    ),
  );
}

class _SettlementDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> settlement;
  final String docId;
  final NumberFormat currencyFmt;
  final DateFormat dateFmt;

  const _SettlementDetailSheet({
    required this.settlement,
    required this.docId,
    required this.currencyFmt,
    required this.dateFmt,
  });

  @override
  ConsumerState<_SettlementDetailSheet> createState() =>
      _SettlementDetailSheetState();
}

class _SettlementDetailSheetState
    extends ConsumerState<_SettlementDetailSheet> {
  late Future<String> _storeNameFuture;
  late Future<QuerySnapshot<Map<String, dynamic>>> _transactionFuture;

  String get _sellerId =>
      widget.settlement['sellerId'] as String? ??
      widget.settlement['storeId'] as String? ??
      'Unknown';

  @override
  void initState() {
    super.initState();
    _storeNameFuture = ref
        .read(adminNameResolverProvider.notifier)
        .resolveStoreName(_sellerId);

    final status = widget.settlement['status'] as String? ?? 'pending';
    _transactionFuture = status == 'completed'
        ? ref
              .read(firebaseFirestoreProvider)
              .collection('transactions')
              .where('referenceId', isEqualTo: widget.docId)
              .limit(1)
              .get()
        : Future.error('not completed');
  }

  @override
  Widget build(BuildContext context) {
    final settlement = widget.settlement;
    final docId = widget.docId;
    final currencyFmt = widget.currencyFmt;
    final dateFmt = widget.dateFmt;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecond
        : AppColors.lightTextSecond;
    final status = settlement['status'] as String? ?? 'pending';
    final amount = (settlement['amount'] as num?)?.toDouble() ?? 0.0;
    final sellerId = _sellerId;
    final requestedAt =
        settlement['requestedAt'] as Timestamp? ??
        settlement['createdAt'] as Timestamp?;
    final processedAt = settlement['processedAt'] as Timestamp?;
    final rejectedAt = settlement['rejectedAt'] as Timestamp?;
    final rejectionReason = settlement['rejectionReason'] as String?;
    final adminNote = settlement['adminNote'] as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settlement Details',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AdminStatusPill(
                    label: status.toUpperCase(),
                    color: switch (status) {
                      'pending' => const Color(0xFFF59E0B),
                      'processing' => const Color(0xFF2563EB),
                      'completed' => AppColors.success,
                      'failed' => AppColors.error,
                      _ => Colors.grey,
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AdminSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Settlement ID', docId, secondaryTextColor),
                    FutureBuilder<String>(
                      future: _storeNameFuture,
                      builder: (context, snapshot) => _detailRow(
                        'Seller Store',
                        snapshot.data ?? 'Loading...',
                        secondaryTextColor,
                      ),
                    ),
                    _detailRow('Seller ID', sellerId, secondaryTextColor),
                    _detailRow(
                      'Amount',
                      currencyFmt.format(amount),
                      secondaryTextColor,
                      valueColor: AppColors.primary,
                    ),
                    _detailRow(
                      'Currency',
                      settlement['currency'] as String? ?? 'INR',
                      secondaryTextColor,
                    ),
                    _detailRow(
                      'Bank Account (IFSC)',
                      settlement['bankAccountId'] as String? ?? '—',
                      secondaryTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (rejectionReason != null &&
                  rejectionReason.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Rejection Reason',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rejectionReason,
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (adminNote != null && adminNote.trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.sticky_note_2_outlined,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Internal Note',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(adminNote, style: GoogleFonts.inter(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Timeline',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              AdminSectionCard(
                child: _SettlementTimeline(
                  status: status,
                  requestedAt: requestedAt?.toDate(),
                  processedAt: processedAt?.toDate(),
                  rejectedAt: rejectedAt?.toDate(),
                  dateFmt: dateFmt,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
              if (status == 'completed') ...[
                const SizedBox(height: 16),
                Text(
                  'Linked Transaction',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: _transactionFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError ||
                        (snapshot.data?.docs.isEmpty ?? true)) {
                      return AdminSectionCard(
                        child: Text(
                          'No linked transaction found',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: secondaryTextColor,
                          ),
                        ),
                      );
                    }
                    final txData = snapshot.data!.docs.first.data();
                    final txId = snapshot.data!.docs.first.id;
                    final txAmount =
                        (txData['amount'] as num?)?.toDouble() ?? 0.0;
                    final txType = txData['type'] as String? ?? '—';
                    final txStatus = txData['status'] as String? ?? '—';
                    final txCompletedAt = (txData['completedAt'] as Timestamp?)
                        ?.toDate();

                    return AdminSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow(
                            'Transaction ID',
                            txId,
                            secondaryTextColor,
                          ),
                          _detailRow('Type', txType, secondaryTextColor),
                          _detailRow('Status', txStatus, secondaryTextColor),
                          _detailRow(
                            'Amount',
                            currencyFmt.format(txAmount),
                            secondaryTextColor,
                            valueColor: AppColors.success,
                          ),
                          _detailRow(
                            'Completed At',
                            txCompletedAt != null
                                ? dateFmt.format(txCompletedAt)
                                : '—',
                            secondaryTextColor,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(
    String label,
    String value,
    Color secondaryTextColor, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: secondaryTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementTimeline extends StatelessWidget {
  final String status;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final DateTime? rejectedAt;
  final DateFormat dateFmt;
  final Color secondaryTextColor;

  const _SettlementTimeline({
    required this.status,
    required this.requestedAt,
    required this.processedAt,
    required this.rejectedAt,
    required this.dateFmt,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'failed';
    final isCompleted = status == 'completed';
    final isProcessing = status == 'processing';

    final steps = <_TimelineStepData>[
      _TimelineStepData(
        label: 'Requested',
        timestamp: requestedAt,
        isDone: true,
        color: AppColors.info,
        icon: Icons.send_rounded,
      ),
      _TimelineStepData(
        label: 'Processing',
        timestamp: isProcessing || isCompleted ? processedAt : null,
        isDone: isProcessing || isCompleted,
        color: const Color(0xFF2563EB),
        icon: Icons.autorenew_rounded,
      ),
      if (isRejected)
        _TimelineStepData(
          label: 'Rejected',
          timestamp: rejectedAt,
          isDone: true,
          color: AppColors.error,
          icon: Icons.close_rounded,
        )
      else
        _TimelineStepData(
          label: 'Completed',
          timestamp: isCompleted ? processedAt : null,
          isDone: isCompleted,
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          _TimelineStep(
            data: steps[i],
            isLast: i == steps.length - 1,
            dateFmt: dateFmt,
            secondaryTextColor: secondaryTextColor,
          ),
      ],
    );
  }
}

class _TimelineStepData {
  final String label;
  final DateTime? timestamp;
  final bool isDone;
  final Color color;
  final IconData icon;

  _TimelineStepData({
    required this.label,
    required this.timestamp,
    required this.isDone,
    required this.color,
    required this.icon,
  });
}

class _TimelineStep extends StatelessWidget {
  final _TimelineStepData data;
  final bool isLast;
  final DateFormat dateFmt;
  final Color secondaryTextColor;

  const _TimelineStep({
    required this.data,
    required this.isLast,
    required this.dateFmt,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = data.isDone
        ? data.color
        : secondaryTextColor.withValues(alpha: 0.4);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: data.isDone ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, size: 14, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: data.isDone ? null : secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.timestamp != null
                        ? dateFmt.format(data.timestamp!)
                        : 'Pending',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarlyReleaseRequestsSection extends ConsumerWidget {
  final NumberFormat currencyFmt;

  const _EarlyReleaseRequestsSection({required this.currencyFmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('escrows')
          .where('status', isEqualTo: 'release_requested')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: AdminSectionCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flash_on_rounded,
                      size: 16,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Early Escrow Release Requests (${docs.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final escrowId = docs[index].id;
                    final storeId = data['storeId'] as String? ?? '';
                    final orderId = data['orderId'] as String? ?? '';
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                    
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ResolvedStoreName(storeId: storeId),
                              const SizedBox(height: 2),
                              Text(
                                'Order #${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFmt.format(amount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => _approveEarlyRelease(context, ref, escrowId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Approve', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _approveEarlyRelease(BuildContext context, WidgetRef ref, String escrowId) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return;

      final response = await http.post(
        Uri.parse('https://releasematuredescrows-oshbhnscba-uc.a.run.app'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'escrowId': escrowId}),
      ).timeout(const Duration(seconds: 15));

      if (context.mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Escrow released successfully to wallet'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to release escrow: ${response.body}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to release escrow: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
