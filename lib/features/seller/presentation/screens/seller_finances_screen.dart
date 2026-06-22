import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SellerFinancesScreen extends StatelessWidget {
  const SellerFinancesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/seller/dashboard'),
        ),
        title: const Text('Finances'),
      ),
      body: const Center(child: Text('Finance Dashboard Coming Soon')),
    );
  }
}
