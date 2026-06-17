import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const secondary = Color(0xFF0EA5E9);

  // Success
  static const success = Color(0xFF16A34A);

  // Warning
  static const warning = Color(0xFFF59E0B);

  // Error
  static const error = Color(0xFFDC2626);

  // Light Theme
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Colors.white;
  static const lightCard = Colors.white;

  // Dark Theme
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF111827);
  static const darkCard = Color(0xFF1E293B);

  static const lightTextPrimary = Color(0xFF0F172A);
  static const lightTextSecondary = Color(0xFF64748B);

  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFF94A3B8);

  static const border = Color(0xFFE2E8F0);
}