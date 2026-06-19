import 'package:flutter/material.dart';

class AppPriceText extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String currency;

  const AppPriceText({
    super.key,
    required this.amount,
    this.style,
    this.currency = '₹',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      '$currency${amount.toStringAsFixed(2)}',
      style:
          style ??
          theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
    );
  }
}
