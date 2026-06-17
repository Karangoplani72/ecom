import 'package:flutter/material.dart';

class AppStoreCard extends StatelessWidget {
  final String storeName;
  final String description;
  final VoidCallback onTap;

  const AppStoreCard({
    super.key,
    required this.storeName,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.store),
        title: Text(storeName),
        subtitle: Text(description),
      ),
    );
  }
}