import 'package:flutter/material.dart';

import 'app_network_image.dart';
import 'app_price_text.dart';
import 'app_rating_bar.dart';

class AppProductCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double rating;
  final num price;
  final VoidCallback onTap;

  const AppProductCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  AppPriceText(amount: price),
                  const SizedBox(height: 4),
                  AppRatingBar(rating: rating),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}