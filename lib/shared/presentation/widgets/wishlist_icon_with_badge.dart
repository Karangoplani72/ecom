import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/core/theme/app_colors.dart';

class WishlistIconWithBadge extends ConsumerWidget {
  final Color? color;

  const WishlistIconWithBadge({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistStreamProvider);
    final count = wishlistAsync.maybeWhen(
      data: (items) => items.length,
      orElse: () => 0,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final iconColor = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            count > 0 ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: count > 0 ? const Color(0xFFEC4899) : iconColor,
            size: 26,
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBgPrimary : AppColors.lightBgPrimary,
                    width: 1.5,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () => context.push('/buyer/wishlist'),
    );
  }
}
