import 'package:flutter/material.dart';

class SellerOrderStatusChip extends StatelessWidget {
  final String status;
  final double? fontSize;
  final EdgeInsets? padding;

  static const Map<String, Color> statusColors = {
    'pending': Color(0xFFFFC107),
    'confirmed': Color(0xFF2196F3),
    'processing': Color(0xFF9C27B0),
    'shipped': Color(0xFF00BCD4),
    'delivered': Color(0xFF4CAF50),
    'cancelled': Color(0xFFF44336),
    'refunded': Color(0xFFFF9800),
  };

  static const Map<String, String> statusLabels = {
    'pending': 'Pending',
    'confirmed': 'Confirmed',
    'processing': 'Processing',
    'shipped': 'Shipped',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
    'refunded': 'Refunded',
  };

  const SellerOrderStatusChip({
    super.key,
    required this.status,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColors[status] ?? Colors.grey;
    final label = statusLabels[status] ?? status;

    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
