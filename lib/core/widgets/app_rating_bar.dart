import 'package:flutter/material.dart';

class AppRatingBar extends StatelessWidget {
  final double rating;

  const AppRatingBar({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1)),
      ],
    );
  }
}