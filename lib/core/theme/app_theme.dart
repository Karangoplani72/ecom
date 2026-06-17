import 'package:flutter/material.dart';
import 'app_colors.dart';

final class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),

    scaffoldBackgroundColor: AppColors.lightBackground,

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.lightTextPrimary,
    ),

    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(
          color: AppColors.border,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.lightTextPrimary,
      ),
      bodyMedium: TextStyle(
        color: AppColors.lightTextSecondary,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),

    scaffoldBackgroundColor: AppColors.darkBackground,

    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: AppColors.darkBackground,
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: TextStyle(
        color: AppColors.darkTextSecondary,
      ),
    ),
  );
}