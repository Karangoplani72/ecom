import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/features/admin/data/services/admin_name_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firebaseFirestoreProvider);

    return AdminScaffold(
      title: 'Order Details',
      subtitle: 'View complete order information',
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestore.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AdminEmptyRow(icon: Icons.error_outline, message: snapshot.error.toString());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const AdminEmptyRow(
              icon: Icons.receipt_long_outlined,
              message: 'Order not found',
            );
          }
          final order = <String, dynamic>{'id': snapshot.data!.id, ...snapshot.data!.data()! as Map<String, dynamic>};
          return _OrderDetailView(order: order);
        },
      ),
    );
  }
}

class _OrderDetailView extends ConsumerWidget {
  final Map<String, dynamic> order;
  const _OrderDetailView({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');

    final status = order['status'] as String? ?? 'pending';
    final items = order['items'] as List<dynamic>? ?? [];
    final shippingAddress = order['shippingAddress'] as Map<String, dynamic>? ?? {};
    final paymentInfo = order['paymentInfo'] as Map<String, dynamic>? ?? {};

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'processing':
        statusColor = const Color(0xFF2563EB);
        break;
      case 'shipped':
        statusColor = const Color(0xFF7C3AED);
        break;
      case 'delivered':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Order Header
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order['id'].toString().substring(0, 10).toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  AdminStatusPill(label: status.toUpperCase(), color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Placed on ${dateFmt.format((order['createdAt'] as Timestamp).toDate())}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    currencyFmt.format((order['totalAmount'] as num?)?.toDouble() ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Customer Info
        _SectionHeader('Customer Information'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: ref.read(adminNameResolverProvider.notifier).resolveUserName(order['buyerId'] as String? ?? ''),
                builder: (context, snapshot) {
                  return _InfoRow(
                    label: 'Customer Name',
                    value: snapshot.data ?? 'Loading...',
                  );
                },
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Customer ID',
                value: order['buyerId'] as String? ?? 'Unknown',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Email',
                value: order['customerEmail'] as String? ?? 'Not provided',
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Phone',
                value: order['customerPhone'] as String? ?? 'Not provided',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Shipping Address
        _SectionHeader('Shipping Address'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shippingAddress['name'] as String? ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                shippingAddress['addressLine1'] as String? ?? '',
                style: const TextStyle(fontSize: 13),
              ),
              if (shippingAddress['addressLine2'] != null)
                Text(
                  shippingAddress['addressLine2'] as String,
                  style: const TextStyle(fontSize: 13),
                ),
              const SizedBox(height: 4),
              Text(
                '${shippingAddress['city'] ?? ''}, ${shippingAddress['state'] ?? ''} - ${shippingAddress['pincode'] ?? ''}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                'Phone: ${shippingAddress['phone'] ?? 'Not provided'}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Order Items
        _SectionHeader('Order Items (${items.length})'),
        ...items.asMap().entries.map((entry) {
          final item = entry.value as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AdminSectionCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (item['imageUrl'] as String? ?? '').isNotEmpty
                        ? Image.network(
                            item['imageUrl'] as String,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => _fallbackImage(),
                          )
                        : _fallbackImage(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String? ?? 'Unknown Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item['quantity'] ?? 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          currencyFmt.format((item['price'] as num?)?.toDouble() ?? 0),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currencyFmt.format(((item['price'] as num?)?.toDouble() ?? 0) * (item['quantity'] as num? ?? 1)),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),

        // Payment Info
        _SectionHeader('Payment Information'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                label: 'Payment Method',
                value: (paymentInfo['method'] as String? ?? 'Unknown').toUpperCase(),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Payment Status',
                value: (paymentInfo['status'] as String? ?? 'Unknown').toUpperCase(),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'Transaction ID',
                value: paymentInfo['transactionId'] as String? ?? 'Not provided',
              ),
              if (paymentInfo['paidAt'] != null) ...[
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Paid At',
                  value: dateFmt.format((paymentInfo['paidAt'] as Timestamp).toDate()),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Order Actions
        _SectionHeader('Order Actions'),
        AdminSectionCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status: $status',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _getAvailableActions(status).map((action) {
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _getActionColor(action),
                      side: BorderSide(color: _getActionColor(action)),
                    ),
                    onPressed: () => _updateOrderStatus(context, ref, action),
                    child: Text(action.toUpperCase()),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  List<String> _getAvailableActions(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return ['processing', 'cancelled'];
      case 'processing':
        return ['shipped', 'cancelled'];
      case 'shipped':
        return ['delivered', 'cancelled'];
      case 'delivered':
        return ['refunded'];
      case 'cancelled':
        return [];
      default:
        return [];
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'cancelled':
      case 'refunded':
        return AppColors.error;
      case 'processing':
        return const Color(0xFF2563EB);
      case 'shipped':
        return const Color(0xFF7C3AED);
      case 'delivered':
        return AppColors.success;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateOrderStatus(
    BuildContext context,
    WidgetRef ref,
    String newStatus,
  ) async {
    // Intercept refund — requires reason modal
    if (newStatus == 'refunded') {
      await _showRefundModal(context, ref);
      return;
    }
    final result = await ref
        .read(adminControllerProvider.notifier)
        .updateOrderStatus(order['id'] as String, newStatus);

    if (!context.mounted) return;
    result.fold(
      (err) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      ),
    );
  }

  Future<void> _showRefundModal(BuildContext context, WidgetRef ref) async {
    final reasonController = TextEditingController();
    String selectedCategory = 'Defective product';
    final orderTotal = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final amountController = TextEditingController(text: orderTotal.toStringAsFixed(2));
    bool confirmed = false;

    final categories = [
      'Defective product',
      'Item not received',
      'Wrong item sent',
      'Customer request',
      'Fraud / Dispute resolution',
      'Other',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final isValid = reasonController.text.trim().length >= 10
                && amountController.text.isNotEmpty
                && double.tryParse(amountController.text) != null
                && (double.tryParse(amountController.text) ?? 0) > 0
                && confirmed;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 24, 24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.assignment_return_outlined,
                          color: Colors.red, size: 22),
                      const SizedBox(width: 10),
                      Text('Process Refund',
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Reason category dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Reason category *',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Detailed reason text field
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Detailed reason * (min 10 characters)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Refund amount
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Refund amount (₹) *',
                      hintText: 'Order total: ₹${orderTotal.toStringAsFixed(2)}',
                      border: const OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  // Confirmation checkbox
                  CheckboxListTile(
                    value: confirmed,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'I confirm this refund has been reviewed and approved',
                      style: TextStyle(fontSize: 13),
                    ),
                    onChanged: (v) => setState(() => confirmed = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isValid
                          ? () async {
                              Navigator.of(ctx).pop();
                              final result = await ref
                                  .read(adminControllerProvider.notifier)
                                  .processRefund(
                                    orderId: order['id'] as String,
                                    reason: reasonController.text.trim(),
                                    reasonCategory: selectedCategory,
                                    refundAmount: double.parse(
                                        amountController.text),
                                  );
                              if (!context.mounted) return;
                              result.fold(
                                (err) => ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                        SnackBar(content: Text(err))),
                                (_) => ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                  content: Text('Refund processed successfully'),
                                  backgroundColor: Colors.red,
                                )),
                              );
                            }
                          : null,
                      child: const Text('Confirm Refund',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
