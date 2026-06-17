import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  final String label;

  const AppBadge({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context)
              .colorScheme
              .primary,
        ),
      ),
    );
  }
}