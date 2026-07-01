import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/admin/data/services/admin_name_resolver.dart';

class AdminEarlyReleasesScreen extends ConsumerStatefulWidget {
  const AdminEarlyReleasesScreen({super.key});

  @override
  ConsumerState<AdminEarlyReleasesScreen> createState() => _AdminEarlyReleasesScreenState();
}

class _AdminEarlyReleasesScreenState extends ConsumerState<AdminEarlyReleasesScreen> {
  final Map<String, bool> _processingRequests = {};
  final NumberFormat _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  Future<void> _approveEarlyRelease(BuildContext context, String escrowId) async {
    setState(() => _processingRequests[escrowId] = true);
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw Exception('User is not authenticated.');
      }

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
              content: Text('Escrow released successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['error'] ?? response.body;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to release escrow: $errorMsg'),
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
    } finally {
      if (mounted) {
        setState(() => _processingRequests[escrowId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firebaseFirestoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminScaffold(
      title: 'Early Escrow Releases',
      subtitle: 'Review and approve manual early release requests from sellers',
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('escrows')
            .where('status', isEqualTo: 'release_requested')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AdminEmptyRow(
                  icon: Icons.error_outline,
                  message: 'Error fetching requests: ${snapshot.error}',
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Calculate destination metrics
          int walletCount = 0;
          int bankCount = 0;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['releaseTarget'] == 'bank') {
              bankCount++;
            } else {
              walletCount++;
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AdminMetricGrid(
                metrics: [
                  AdminMetricCard(
                    label: 'Total Requests',
                    value: docs.length.toString(),
                    icon: Icons.flash_on_rounded,
                    color: Colors.teal,
                  ),
                  AdminMetricCard(
                    label: 'To Bank (Razorpay)',
                    value: bankCount.toString(),
                    icon: Icons.account_balance_rounded,
                    color: Colors.blue,
                  ),
                  AdminMetricCard(
                    label: 'To Wallet',
                    value: walletCount.toString(),
                    icon: Icons.wallet_rounded,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Pending Requests',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: AdminEmptyRow(
                    icon: Icons.check_circle_outline_rounded,
                    message: 'No pending early release requests.',
                  ),
                )
              else
                ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final escrowId = doc.id;
                final storeId = data['storeId'] as String? ?? '';
                final orderId = data['orderId'] as String? ?? '';
                final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                final isProcessing = _processingRequests[escrowId] ?? false;
                final releaseTarget = data['releaseTarget'] as String? ?? 'wallet';
                final reason = data['releaseReason'] as String? ?? '';
                final requestedAt = (data['releaseRequestedAt'] as Timestamp?)?.toDate();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AdminSectionCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Store Icon / Details
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _ResolvedStoreName(storeId: storeId),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Order #${orderId.length >= 8 ? orderId.substring(0, 8).toUpperCase() : orderId.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (releaseTarget == 'bank' ? Colors.blue : Colors.purple).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      releaseTarget == 'bank' ? 'TO BANK' : 'TO WALLET',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: releaseTarget == 'bank' ? Colors.blue.shade700 : Colors.purple.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (reason.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Reason: $reason',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                              if (requestedAt != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Requested: ${DateFormat('d MMM yyyy, h:mm a').format(requestedAt)}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right: Amount and Actions
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _currencyFmt.format(amount),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: isProcessing ? null : () => _approveEarlyRelease(context, escrowId),
                              icon: isProcessing
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline_rounded, size: 14),
                              label: Text(
                                isProcessing ? 'Processing' : 'Approve Release',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ResolvedStoreName extends ConsumerWidget {
  final String storeId;

  const _ResolvedStoreName({required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: ref.read(adminNameResolverProvider.notifier).resolveStoreName(storeId),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? storeId,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
