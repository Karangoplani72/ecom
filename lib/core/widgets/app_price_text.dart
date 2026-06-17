import 'package:flutter/material.dart';

class AppPriceText extends StatelessWidget {
  final num amount;

  const AppPriceText({
    super.key,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '₹${amount.toStringAsFixed(0)}',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}