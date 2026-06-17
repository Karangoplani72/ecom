import 'package:flutter/material.dart';

class AppOrderCard extends StatelessWidget {
  final String orderId;
  final String status;
  final double amount;

  const AppOrderCard({
    super.key,
    required this.orderId,
    required this.status,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(orderId),
        subtitle: Text(status),
        trailing: Text(
          '₹${amount.toStringAsFixed(2)}',
        ),
      ),
    );
  }
}