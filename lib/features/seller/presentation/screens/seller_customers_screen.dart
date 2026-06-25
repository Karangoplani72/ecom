import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SellerCustomersScreen extends StatelessWidget {
  const SellerCustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Customers'),
      ),
      body: const Center(child: Text('Customer Management Coming Soon')),
    );
  }
}
