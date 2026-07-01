import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/features/seller/domain/entities/merchant_wallet.dart';
import 'package:ecom/features/seller/domain/entities/seller_transaction.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_finances_controller.dart';
import 'package:ecom/services/ifsc_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─── Extra Providers ──────────────────────────────────────────────────────────

/// Streams all payout requests for this seller from the `payouts` collection.
final sellerPayoutsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final sellerId = ref.watch(currentUserIdProvider);
      if (sellerId == null || sellerId.isEmpty) return Stream.value([]);

      return ref
          .watch(firebaseFirestoreProvider)
          .collection('payouts')
          .where('storeId', isEqualTo: sellerId)
          .orderBy('requestedAt', descending: true)
          .snapshots()
          .map(
            (s) => s.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList(),
          );
    });

final sellerPendingEscrowsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final sellerId = ref.watch(currentUserIdProvider);
  if (sellerId == null || sellerId.isEmpty) return Stream.value([]);
  return firestore
      .collection('escrows')
      .where('storeId', isEqualTo: sellerId)
      .where('status', whereIn: ['pending', 'release_requested'])
      .snapshots()
      .map((snap) => snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          }).toList());
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class SellerFinancesScreen extends ConsumerStatefulWidget {
  const SellerFinancesScreen({super.key});

  @override
  ConsumerState<SellerFinancesScreen> createState() =>
      _SellerFinancesScreenState();
}

class _SellerFinancesScreenState extends ConsumerState<SellerFinancesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(sellerFinancesControllerProvider.notifier).refresh();
    ref.invalidate(sellerBankAccountProvider);
    ref.invalidate(sellerTransactionsProvider);
    ref.invalidate(sellerPayoutsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(sellerFinancesControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : AppColors.lightBgPrimary,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkBgSurface
            : AppColors.lightBgSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Finances & Settlements',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecond
              : AppColors.lightTextSecond,
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'Payouts'),
          ],
        ),
      ),
      body: walletAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, _) =>
            AppErrorView(message: error.toString(), onRetry: _refresh),
        data: (wallet) => RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(wallet: wallet),
              _TransactionsTab(),
              _PayoutsTab(wallet: wallet),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tab 1: Overview ─────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final MerchantWallet wallet;

  const _OverviewTab({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankAsync = ref.watch(sellerBankAccountProvider);
    final txAsync = ref.watch(sellerTransactionsProvider);
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Wallet card ──────────────────────────────────────────────────
          _WalletCard(wallet: wallet, currencyFmt: currencyFmt),
          const SizedBox(height: 20),

          // ── Quick stats row ──────────────────────────────────────────────
          txAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
            data: (txList) {
              final payoutsAsync = ref.watch(sellerPayoutsProvider);
              final payouts = payoutsAsync.when(
                data: (data) => data,
                loading: () => <Map<String, dynamic>>[],
                error: (e, s) => <Map<String, dynamic>>[],
              );
              return _EarningsSummary(
                transactions: txList,
                payouts: payouts,
                currencyFmt: currencyFmt,
                isDark: isDark,
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Bank account ─────────────────────────────────────────────────
          _BankAccountSection(bankAsync: bankAsync),
          const SizedBox(height: 20),

          // ── Withdraw CTA ─────────────────────────────────────────────────
          bankAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
            data: (bank) {
              if (bank == null) {
                return _InfoCard(
                  icon: Icons.info_outline_rounded,
                  title: 'Configure bank account first',
                  subtitle:
                      'Add your settlement bank account above before requesting a payout.',
                  color: AppColors.warning,
                );
              }
              if (wallet.availableBalance <= 0) {
                return _InfoCard(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No balance to withdraw',
                  subtitle:
                      'Your available balance will appear here once orders are settled.',
                  color: AppColors.info,
                );
              }
              return _WithdrawButton(wallet: wallet, bank: bank);
            },
          ),
          if (wallet.lockedBalance > 0) ...[
            const SizedBox(height: 20),
            _PendingEscrowsSection(currencyFmt: currencyFmt),
          ],
        ],
      ),
    );
  }
}

class _WalletCard extends ConsumerWidget {
  final MerchantWallet wallet;
  final NumberFormat currencyFmt;

  const _WalletCard({required this.wallet, required this.currencyFmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Merchant Wallet',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currencyFmt.format(wallet.availableBalance),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Available Balance',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WalletStat(
                  label: 'Locked (Escrow)',
                  value: currencyFmt.format(wallet.lockedBalance),
                  tooltip:
                      'Funds from recent orders are held in escrow for 10 days before being released.',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _WalletStat(
                  label: 'Total Balance',
                  value: currencyFmt.format(wallet.totalBalance),
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletStat extends StatelessWidget {
  final String label;
  final String value;
  final String? tooltip;
  final CrossAxisAlignment align;

  const _WalletStat({
    required this.label,
    required this.value,
    this.tooltip,
    this.align = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: tooltip,
            preferBelow: false,
            child: const Icon(
              Icons.info_outline,
              color: Colors.white38,
              size: 13,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.only(
        left: align == CrossAxisAlignment.start ? 0 : 12,
        right: align == CrossAxisAlignment.end ? 0 : 12,
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          labelWidget,
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsSummary extends StatelessWidget {
  final List<SellerTransaction> transactions;
  final List<Map<String, dynamic>> payouts;
  final NumberFormat currencyFmt;
  final bool isDark;

  const _EarningsSummary({
    required this.transactions,
    required this.payouts,
    required this.currencyFmt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    double thisMonth = 0;
    double thisWeek = 0;
    double totalPaidOut = 0;
    int pendingCount = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.adjustment &&
          tx.status == TransactionStatus.completed &&
          tx.amount > 0) {
        if (tx.createdAt.isAfter(startOfMonth)) thisMonth += tx.amount;
        if (tx.createdAt.isAfter(startOfWeek)) thisWeek += tx.amount;
      }
      if (tx.type == TransactionType.payoutCompleted &&
          tx.status == TransactionStatus.completed) {
        totalPaidOut += tx.amount.abs();
      }
    }

    for (final payout in payouts) {
      if (payout['status'] == 'pending') {
        pendingCount++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Earnings Summary',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'This Week',
                value: currencyFmt.format(thisWeek),
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                label: 'This Month',
                value: currencyFmt.format(thisMonth),
                icon: Icons.calendar_month_rounded,
                color: AppColors.primary,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatChip(
                label: 'Total Paid Out',
                value: currencyFmt.format(totalPaidOut),
                icon: Icons.payment_rounded,
                color: const Color(0xFF0EA5E9),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatChip(
                label: 'Pending Requests',
                value: pendingCount.toString(),
                icon: Icons.hourglass_top_rounded,
                color: AppColors.warning,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark
                  ? AppColors.darkTextSecond
                  : AppColors.lightTextSecond,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankAccountSection extends ConsumerWidget {
  final AsyncValue<Map<String, dynamic>?> bankAsync;

  const _BankAccountSection({required this.bankAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Settlement Account',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            ?bankAsync.whenOrNull(
              data: (bank) => TextButton.icon(
                onPressed: () => _showBankDialog(context, bank),
                icon: Icon(
                  bank == null ? Icons.add_rounded : Icons.edit_rounded,
                  size: 16,
                ),
                label: Text(bank == null ? 'Add' : 'Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        bankAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) =>
              Text('Error: $e', style: const TextStyle(color: AppColors.error)),
          data: (bank) {
            if (bank == null) {
              return _EmptyBankCard(
                onAdd: () => _showBankDialog(context, null),
              );
            }
            return _BankCard(bank: bank, isDark: isDark);
          },
        ),
      ],
    );
  }

  void _showBankDialog(BuildContext context, Map<String, dynamic>? bank) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BankAccountDialog(currentBank: bank),
    );
  }
}

class _EmptyBankCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBankCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBgSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
            style: BorderStyle.none,
          ),
          // Dashed border via custom paint is complex; using dotted effect
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Settlement Account',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Required to receive payout transfers',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecond
                          : AppColors.lightTextSecond,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  final Map<String, dynamic> bank;
  final bool isDark;

  const _BankCard({required this.bank, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank['bankName'] as String? ?? 'Bank',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'IFSC Verified',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BankRow(
            label: 'Holder',
            value: bank['holderName'] as String? ?? '',
            isDark: isDark,
          ),
          _BankRow(
            label: 'Account',
            value: bank['maskedAccountNumber'] as String? ?? '',
            isDark: isDark,
          ),
          _BankRow(
            label: 'IFSC',
            value: bank['ifsc'] as String? ?? '',
            isDark: isDark,
          ),
          _BankRow(
            label: 'Branch',
            value: bank['branch'] as String? ?? '',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _BankRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecond
                    : AppColors.lightTextSecond,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawButton extends ConsumerWidget {
  final MerchantWallet wallet;
  final Map<String, dynamic> bank;

  const _WithdrawButton({required this.wallet, required this.bank});

  static const double _minWithdrawal = 500;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canWithdraw = wallet.availableBalance >= _minWithdrawal;
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: canWithdraw
                  ? AppColors.primary
                  : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: canWithdraw ? 4 : 0,
            ),
            onPressed: canWithdraw
                ? () => _showWithdrawSheet(context, ref)
                : null,
            icon: const Icon(Icons.account_balance_wallet_rounded),
            label: Text(
              canWithdraw
                  ? 'Request Withdrawal'
                  : 'Min. ${currencyFmt.format(_minWithdrawal)} required',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (!canWithdraw)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Available: ${currencyFmt.format(wallet.availableBalance)} · '
              'Need ${currencyFmt.format(_minWithdrawal - wallet.availableBalance)} more',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning),
            ),
          ),
      ],
    );
  }

  void _showWithdrawSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(wallet: wallet, bank: bank),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecond
                        : AppColors.lightTextSecond,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Transactions ──────────────────────────────────────────────────────

class _TransactionsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<_TransactionsTab> {
  String _typeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(sellerTransactionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Filter chips
        Container(
          color: isDark ? AppColors.darkBgSurface : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in [
                  ('all', 'All'),
                  ('order_revenue', 'Revenue'),
                  ('payout_request', 'Payout Req.'),
                  ('payout_completed', 'Paid Out'),
                  ('refund', 'Refunds'),
                  ('platform_fee', 'Fees'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.$2, style: GoogleFonts.inter(fontSize: 12)),
                      selected: _typeFilter == f.$1,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      onSelected: (_) => setState(() => _typeFilter = f.$1),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: txAsync.when(
            loading: () => const AppLoadingView(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (transactions) {
              final filtered = _typeFilter == 'all'
                  ? transactions
                  : transactions
                        .where((tx) => tx.type.value == _typeFilter)
                        .toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 48,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions found',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.darkTextSecond
                              : AppColors.lightTextSecond,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _TransactionTile(
                  tx: filtered[i],
                  currencyFmt: currencyFmt,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final SellerTransaction tx;
  final NumberFormat currencyFmt;
  final bool isDark;

  const _TransactionTile({
    required this.tx,
    required this.currencyFmt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Only escrow releases (adjustment) and order revenue count as credits to seller
    final isCredit =
        tx.type == TransactionType.adjustment ||
        tx.type == TransactionType.orderRevenue;
    final dateFmt = DateFormat('d MMM yyyy • h:mm a');

    IconData txIcon;
    Color txColor;

    switch (tx.type.value) {
      case 'order_revenue':
      case 'adjustment':
        txIcon = Icons.arrow_downward_rounded;
        txColor = AppColors.success;
        break;
      case 'payout':
      case 'payout_request':
        txIcon = Icons.schedule_rounded;
        txColor = AppColors.warning;
        break;
      case 'payout_completed':
        txIcon = Icons.arrow_upward_rounded;
        txColor = const Color(0xFF0EA5E9);
        break;
      case 'refund':
        txIcon = Icons.replay_rounded;
        txColor = Colors.orange;
        break;
      case 'platform_fee':
        txIcon = Icons.percent_rounded;
        txColor = Colors.redAccent;
        break;
      case 'sale':
        txIcon = Icons.shopping_cart_rounded;
        txColor = Colors.blueGrey;
        break;
      default:
        txIcon = Icons.tune_rounded;
        txColor = Colors.grey;
        break;
    }

    Color statusColor;
    switch (tx.status) {
      case TransactionStatus.completed:
        statusColor = AppColors.success;
        break;
      case TransactionStatus.pending:
        statusColor = AppColors.warning;
        break;
      case TransactionStatus.failed:
        statusColor = AppColors.error;
        break;
      case TransactionStatus.cancelled:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white38 : Colors.black45),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: txColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(txIcon, color: txColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description ?? _typeName(tx.type),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      dateFmt.format(tx.createdAt),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.darkTextSecond
                            : AppColors.lightTextSecond,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tx.status.value.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}${currencyFmt.format(tx.amount)}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isCredit ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  String _typeName(TransactionType type) {
    switch (type.value) {
      case 'order_revenue':
        return 'Order Revenue';
      case 'payout_request':
        return 'Payout Request';
      case 'payout_completed':
      case 'payout':
        return 'Payout';
      case 'refund':
        return 'Refund';
      case 'platform_fee':
        return 'Platform Fee';
      case 'adjustment':
        return 'Escrow Release';
      case 'sale':
        return 'Sale Record';
      default:
        return type.value.replaceAll('_', ' ').toUpperCase();
    }
  }
}

// ─── Tab 3: Payouts ───────────────────────────────────────────────────────────

class _PayoutsTab extends ConsumerWidget {
  final MerchantWallet wallet;

  const _PayoutsTab({required this.wallet});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(sellerPayoutsProvider);
    final bankAsync = ref.watch(sellerBankAccountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Column(
      children: [
        // Request payout banner
        bankAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
          data: (bank) => bank != null && wallet.availableBalance >= 500
              ? GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _WithdrawSheet(wallet: wallet, bank: bank),
                  ),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${currencyFmt.format(wallet.availableBalance)} available — Tap to withdraw',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Payout history
        Expanded(
          child: payoutsAsync.when(
            loading: () => const AppLoadingView(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (payouts) {
              if (payouts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 56,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No payout requests yet',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecond
                              : AppColors.lightTextSecond,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Request a withdrawal from the Overview tab',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecond
                              : AppColors.lightTextSecond,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: payouts.length,
                itemBuilder: (ctx, i) => _PayoutTile(
                  payout: payouts[i],
                  currencyFmt: currencyFmt,
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PayoutTile extends StatelessWidget {
  final Map<String, dynamic> payout;
  final NumberFormat currencyFmt;
  final bool isDark;

  const _PayoutTile({
    required this.payout,
    required this.currencyFmt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final status = payout['status'] as String? ?? 'pending';
    final amount = (payout['amount'] as num?)?.toDouble() ?? 0;
    final docId = payout['id'] as String? ?? '';
    final requestedAt = (payout['requestedAt'] as Timestamp?)?.toDate();
    final processedAt = (payout['processedAt'] as Timestamp?)?.toDate();
    final failureReason = payout['rejectionReason'] as String?;
    final dateFmt = DateFormat('d MMM yyyy • h:mm a');

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_top_rounded;
        statusLabel = 'PENDING';
        break;
      case 'processing':
        statusColor = AppColors.info;
        statusIcon = Icons.sync_rounded;
        statusLabel = 'PROCESSING';
        break;
      case 'completed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'COMPLETED';
        break;
      case 'failed':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'REJECTED';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
        statusLabel = status.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payout #${docId.length >= 8 ? docId.substring(0, 8).toUpperCase() : docId.toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (requestedAt != null)
                        Text(
                          'Requested ${dateFmt.format(requestedAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecond
                                : AppColors.lightTextSecond,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? Colors.white38 : Colors.black45),

          // Amount + details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecond
                            : AppColors.lightTextSecond,
                      ),
                    ),
                    Text(
                      currencyFmt.format(amount),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                if (processedAt != null && status == 'completed')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Processed',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecond
                              : AppColors.lightTextSecond,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM yyyy').format(processedAt),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Rejection reason
          if (failureReason != null && status == 'failed')
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.error,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: $failureReason',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Status tracker
          _PayoutStepper(status: status),
        ],
      ),
    );
  }
}

class _PayoutStepper extends StatelessWidget {
  final String status;

  const _PayoutStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    const steps = ['Requested', 'Processing', 'Completed'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int activeStep;
    switch (status) {
      case 'pending':
        activeStep = 0;
        break;
      case 'processing':
        activeStep = 1;
        break;
      case 'completed':
        activeStep = 2;
        break;
      default:
        activeStep = -1; // failed/rejected
    }

    if (activeStep == -1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= activeStep
                        ? AppColors.primary
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: i < activeStep
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        )
                      : i == activeStep
                      ? const Icon(Icons.circle, color: Colors.white, size: 10)
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: i <= activeStep
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: i <= activeStep
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkTextSecond
                              : AppColors.lightTextSecond),
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: i < activeStep
                      ? AppColors.primary
                      : (isDark ? Colors.white12 : Colors.black12),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Withdraw Bottom Sheet ────────────────────────────────────────────────────

class _WithdrawSheet extends ConsumerStatefulWidget {
  final MerchantWallet wallet;
  final Map<String, dynamic> bank;

  const _WithdrawSheet({required this.wallet, required this.bank});

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _submitting = false;

  static const double _minWithdrawal = 500;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final amt = double.parse(_amountController.text.trim());

    try {
      await ref
          .read(sellerFinancesControllerProvider.notifier)
          .requestPayout(
            amount: amt,
            bankAccountId: widget.bank['ifsc'] as String? ?? '',
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payout request submitted! You\'ll be notified once it\'s processed.',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        ref.invalidate(sellerPayoutsProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final available = widget.wallet.availableBalance;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 8, 24, keyboardHeight + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Request Payout',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Funds will be transferred to your registered bank account within 1–3 business days.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecond
                  : AppColors.lightTextSecond,
            ),
          ),
          const SizedBox(height: 20),

          // Bank summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBgPrimary
                  : AppColors.lightBgPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    color: AppColors.success,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.bank['bankName'] as String? ?? 'Bank',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${widget.bank['holderName']} · ${widget.bank['maskedAccountNumber']}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecond
                              : AppColors.lightTextSecond,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount input
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                helperText:
                    'Available: ${currencyFmt.format(available)} · Min: ${currencyFmt.format(_minWithdrawal)}',
                helperStyle: GoogleFonts.inter(fontSize: 11),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Enter an amount';
                }
                final amt = double.tryParse(val.trim());
                if (amt == null || amt <= 0) {
                  return 'Enter a valid amount';
                }
                if (amt < _minWithdrawal) {
                  return 'Minimum withdrawal is ${currencyFmt.format(_minWithdrawal)}';
                }
                if (amt > available) {
                  return 'Exceeds available balance';
                }
                return null;
              },
            ),
          ),

          // Quick amount chips
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final preset in [500, 1000, 2000, 5000])
                  if (preset <= available)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          currencyFmt.format(preset),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () =>
                            _amountController.text = preset.toStringAsFixed(0),
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1,
                        ),
                        labelStyle: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                if (available >= _minWithdrawal)
                  ActionChip(
                    label: Text(
                      'Withdraw All',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () =>
                        _amountController.text = available.toStringAsFixed(0),
                    backgroundColor: AppColors.primary,
                    side: BorderSide.none,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Submit Payout Request',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bank Account Dialog (unchanged, kept for completeness) ───────────────────

class _BankAccountDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? currentBank;

  const _BankAccountDialog({this.currentBank});

  @override
  ConsumerState<_BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends ConsumerState<_BankAccountDialog> {
  static final RegExp _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final RegExp _namePattern = RegExp(r"^[a-zA-Z\s.'-]+$");
  static const int _ifscLength = 11;
  static const int _minAccountNumberLength = 9;
  static const int _maxAccountNumberLength = 18;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _holderController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _confirmAccountNumberController;
  late final TextEditingController _ifscController;

  IfscBankDetails? _verifiedDetails;
  String? _ifscError;
  bool _isFetchingIfsc = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final bank = widget.currentBank;
    final existingAccountNumber = bank?['accountNumber'] as String? ?? '';
    final existingIfsc = (bank?['ifsc'] as String? ?? '').toUpperCase();

    _holderController = TextEditingController(
      text: bank?['holderName'] as String? ?? '',
    );
    _accountNumberController = TextEditingController(
      text: existingAccountNumber,
    );
    _confirmAccountNumberController = TextEditingController(
      text: existingAccountNumber,
    );
    _ifscController = TextEditingController(text: existingIfsc);

    if (existingIfsc.length == _ifscLength &&
        _ifscPattern.hasMatch(existingIfsc)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _verifyIfsc(existingIfsc);
      });
    }
  }

  @override
  void dispose() {
    _holderController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _verifyIfsc(String code) async {
    if (!mounted) return;
    setState(() {
      _isFetchingIfsc = true;
      _ifscError = null;
      _verifiedDetails = null;
    });
    try {
      final details = await IfscService.fetchByIfsc(code);
      if (!mounted) return;
      setState(() {
        _verifiedDetails = details;
        _isFetchingIfsc = false;
      });
    } on IfscNotFoundException catch (e) {
      if (!mounted) return;
      setState(() {
        _ifscError = e.toString();
        _isFetchingIfsc = false;
      });
    } on IfscFetchException catch (e) {
      if (!mounted) return;
      setState(() {
        _ifscError = e.toString();
        _isFetchingIfsc = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ifscError = 'Could not verify IFSC code. Please try again.';
        _isFetchingIfsc = false;
      });
    }
  }

  void _onIfscChanged(String rawValue) {
    final upper = rawValue.toUpperCase();
    if (upper != rawValue) {
      _ifscController.value = TextEditingValue(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }
    setState(() {
      _verifiedDetails = null;
      _ifscError = null;
    });
    if (upper.length == _ifscLength) {
      if (_ifscPattern.hasMatch(upper)) {
        _verifyIfsc(upper);
      } else {
        setState(() => _ifscError = 'Invalid IFSC code format.');
      }
    }
  }

  String? _validateIfsc(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return 'IFSC code is required';
    if (v.length != _ifscLength) return 'IFSC code must be 11 characters';
    if (!_ifscPattern.hasMatch(v)) return 'Invalid IFSC code format';
    if (_isFetchingIfsc) return 'Verifying IFSC code…';
    if (_verifiedDetails == null) return 'Please verify the IFSC code';
    return null;
  }

  String? _validateHolderName(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Account holder name is required';
    if (v.length < 3) return 'Enter a valid name';
    if (!_namePattern.hasMatch(v)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateAccountNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Account number is required';
    if (!RegExp(r'^\d+$').hasMatch(v)) return 'Digits only';
    if (v.length < _minAccountNumberLength) {
      return 'Account number is too short';
    }
    if (v.length > _maxAccountNumberLength) return 'Account number is too long';
    return null;
  }

  String? _validateConfirmAccountNumber(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please confirm the account number';
    if (v != _accountNumberController.text.trim()) {
      return 'Account numbers do not match';
    }
    return null;
  }

  bool get _canSave =>
      _verifiedDetails != null &&
      !_isSaving &&
      !_isFetchingIfsc &&
      _validateHolderName(_holderController.text) == null &&
      _validateAccountNumber(_accountNumberController.text) == null &&
      _validateConfirmAccountNumber(_confirmAccountNumberController.text) ==
          null;

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    final details = _verifiedDetails;
    if (details == null) return;

    setState(() => _isSaving = true);

    try {
      await ref
          .read(sellerFinancesControllerProvider.notifier)
          .updateBankAccount(
            ifsc: _ifscController.text.trim().toUpperCase(),
            accountNumber: _accountNumberController.text.trim(),
            holderName: _holderController.text.trim(),
            bankName: details.bankName,
            branch: details.branch,
            city: details.city,
            bankState: details.state,
            address: details.address,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bank account saved successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget? _buildIfscSuffixIcon() {
    if (_isFetchingIfsc) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_verifiedDetails != null) {
      return const Icon(Icons.check_circle_rounded, color: AppColors.success);
    }
    if (_ifscError != null) {
      return const Icon(Icons.error_rounded, color: AppColors.error);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.currentBank == null
            ? 'Configure Bank Details'
            : 'Edit Bank Details',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                maxLength: _ifscLength,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  labelText: 'IFSC Code',
                  counterText: '',
                  suffixIcon: _buildIfscSuffixIcon(),
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(_ifscLength),
                ],
                onChanged: (v) {
                  _onIfscChanged(v);
                  setState(() {});
                },
                validator: _validateIfsc,
              ),
              if (_ifscError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _ifscError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
              if (_verifiedDetails != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Bank Verified',
                            style: GoogleFonts.inter(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final row in [
                        ('Bank', _verifiedDetails!.bankName),
                        ('Branch', _verifiedDetails!.branch),
                        ('City', _verifiedDetails!.city),
                        ('State', _verifiedDetails!.state),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 50,
                                child: Text(
                                  row.$1,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  row.$2.isEmpty ? '—' : row.$2,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _holderController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
                ),
                validator: _validateHolderName,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNumberController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_maxAccountNumberLength),
                ],
                validator: _validateAccountNumber,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmAccountNumberController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Confirm Account Number',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_maxAccountNumberLength),
                ],
                validator: _validateConfirmAccountNumber,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSave ? _handleSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _PendingEscrowsSection extends ConsumerWidget {
  final NumberFormat currencyFmt;

  const _PendingEscrowsSection({required this.currencyFmt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escrowsAsync = ref.watch(sellerPendingEscrowsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return escrowsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (escrows) {
        if (escrows.isEmpty) return const SizedBox.shrink();

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_clock_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Locked Escrows',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: escrows.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final escrow = escrows[index];
                    final escrowId = escrow['id'] as String? ?? '';
                    final orderId = escrow['orderId'] as String? ?? '';
                    final amount = (escrow['amount'] as num?)?.toDouble() ?? 0.0;
                    final status = escrow['status'] as String? ?? 'pending';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      currencyFmt.format(amount),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      status == 'release_requested'
                                          ? '• Release Requested'
                                          : '• Auto-unlocks in 10 days',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: status == 'release_requested' ? Colors.amber.shade700 : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (status == 'pending')
                            FilledButton.icon(
                              onPressed: () => _showRequestReleaseDialog(context, ref, escrowId, amount),
                              icon: const Icon(Icons.flash_on_rounded, size: 12),
                              label: const Text(
                                'Request Release',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Requested',
                                    style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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

  void _showRequestReleaseDialog(
    BuildContext context,
    WidgetRef ref,
    String escrowId,
    double amount,
  ) {
    String destination = 'wallet';
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Request Early Release'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request release of ₹${amount.toStringAsFixed(0)} before maturation.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Text('Destination', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: destination,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'wallet', child: Text('Wallet Balance')),
                        DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => destination = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Reason for Early Release', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Enter reason (e.g. delivered, customer accepted)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a reason')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    final firestore = ref.read(firebaseFirestoreProvider);
                    final sellerId = ref.read(currentUserIdProvider) ?? '';
                    await firestore.collection('escrows').doc(escrowId).update({
                      'status': 'release_requested',
                      'releaseTarget': destination,
                      'releaseReason': reasonController.text.trim(),
                      'releaseRequestedAt': FieldValue.serverTimestamp(),
                    });
                    
                    // Notify admins in the background
                    try {
                      final storeDoc = await firestore.collection('stores').doc(sellerId).get();
                      final storeName = storeDoc.exists 
                          ? (storeDoc.data()?['storeName'] as String? ?? 'Store') 
                          : 'Store';
                      final adminsSnap = await firestore
                          .collection('users')
                          .where('roles', arrayContains: 'admin')
                          .get();
                      for (final adminDoc in adminsSnap.docs) {
                        await firestore
                            .collection('users')
                            .doc(adminDoc.id)
                            .collection('notifications')
                            .add({
                          'title': '⚡ Early Release Requested',
                          'body': 'Store "$storeName" requested early release of ₹${amount.toStringAsFixed(0)} ($destination).',
                          'deepLinkPath': '/admin/early-releases',
                          'isRead': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                      }
                    } catch (e) {
                      debugPrint('Failed to notify admins: $e');
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Release request submitted to admin')),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
