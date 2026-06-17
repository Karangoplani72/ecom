import 'package:flutter/material.dart';

class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(value),
            Text(title),
          ],
        ),
      ),
    );
  }
}