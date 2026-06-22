import 'package:flutter/material.dart';

abstract final class AppColors {
  // Common
  static const primary = Color(0xFF7C3AED);
  static const primaryDark = Color(0xFFA855F7);
  static const error = Color(0xFFEF4444);
  static const secondary = Color(0xFF0EA5E9); // Legacy alias for admin/seller

  // User-specified Light
  static const lightBgPrimary = Color(0xFFF4F3FF);
  static const lightBgSurface = Color(0xFFFFFFFF);
  static const lightAccentPurple = Color(0xFF7C3AED);
  static const lightAccentViolet = Color(0xFFA855F7);
  static const lightAccentPink = Color(0xFFEC4899);
  static const lightTextPrimary = Color(0xFF1A1A2E);
  static const lightTextSecond = Color(0xFF6B7280);

  // User-specified Dark
  static const darkBgPrimary = Color(0xFF0D0D1A);
  static const darkBgSurface = Color(0xFF1A1A2E);
  static const darkAccentPurple = Color(0xFFA855F7);
  static const darkAccentViolet = Color(0xFFC084FC);
  static const darkAccentPink = Color(0xFFF472B6);
  static const darkTextPrimary = Color(0xFFF5F3FF);
  static const darkTextSecond = Color(0xFFA1A1AA);

  // Legacy mappings for existing code
  static const backgroundLight = lightBgPrimary;
  static const backgroundDark = darkBgPrimary;
  static const surfaceLight = lightBgSurface;
  static const surfaceDark = darkBgSurface;
  static const primaryLight = lightAccentPurple;
  static const textPrimaryLight = lightTextPrimary;
  static const textSecondaryLight = lightTextSecond;
  static const textPrimaryDark = darkTextPrimary;
  static const textSecondaryDark = darkTextSecond;
  static const borderLight = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF2D3748);
  
  // Feedback Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

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