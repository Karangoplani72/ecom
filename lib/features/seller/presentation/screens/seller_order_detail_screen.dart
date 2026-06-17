import 'package:flutter/material.dart';

class SellerOrderDetailScreen extends StatelessWidget {
  final String orderId;

  const SellerOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: Center(
        child: Text('Order ID: $orderId', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
