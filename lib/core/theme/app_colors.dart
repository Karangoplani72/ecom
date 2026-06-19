import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand (Enhanced Premium Blue)
  static const primary = Color(0xFF2563EB); // Royal Blue
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFF60A5FA);
  static const secondary = Color(0xFF0EA5E9);
  
  // Premium Neutrals
  static const backgroundLight = Color(0xFFFBFBFC);
  static const surfaceLight = Colors.white;
  static const backgroundDark = Color(0xFF0A0A0B); // Deep OLED-friendly black
  static const surfaceDark = Color(0xFF131316); // Elevated dark surface

  // Feedback Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Typography
  static const textPrimaryLight = Color(0xFF0F172A);
  static const textSecondaryLight = Color(0xFF64748B);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);

  // Borders & Dividers
  static const borderLight = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF1E293B);

  // Gradients
  static const premiumGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const premiumDarkGradient = LinearGradient(
    colors: [Color(0xFF1E1E24), Color(0xFF0A0A0B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy Aliases (To fix compilation errors in old screens)
  static const border = borderLight;
  static const lightTextSecondary = textSecondaryLight;
  static const darkCard = surfaceDark;
  static const lightCard = surfaceLight;
  static const darkSurface = surfaceDark;
  static const lightSurface = surfaceLight;
}