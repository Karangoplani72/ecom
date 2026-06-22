import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/core/theme/app_colors.dart';

class CartIconWithBadge extends ConsumerWidget {
  final Color? color;

  const CartIconWithBadge({
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartControllerProvider);
    final count = cartItems.fold<int>(0, (sum, item) => sum + item.quantity);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final iconColor = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: iconColor,
            size: 26,
          ),
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899),
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
      onPressed: () => context.push('/buyer/cart'),
    );
  }
}
