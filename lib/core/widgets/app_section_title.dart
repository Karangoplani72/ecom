import 'package:flutter/material.dart';

class AppSectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onTap;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.actionText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onTap,
            child: Text(actionText!),
          ),
      ],
    );
  }
}