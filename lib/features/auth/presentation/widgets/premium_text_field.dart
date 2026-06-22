import 'dart:ui';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                validator: validator,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  prefixIcon: Icon(
                    prefixIcon,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  suffixIcon: suffixIcon,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  errorStyle: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
