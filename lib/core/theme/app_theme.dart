import 'package:flutter/material.dart';

class AppTheme {
  // --------------------------------------------------------------------------
  // CORE COLOR PALETTE (Luxury Blush & Cream)
  // --------------------------------------------------------------------------
  static const Color blushPink = Color(0xFFE8B4B8);
  static const Color roseGold = Color(0xFFD49A9A);
  static const Color champagneGold = Color(0xFFE5D5B5);
  static const Color creamBackground = Color(0xFFFAF9F6); // Soft off-white
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  // Typography Colors
  static const Color charcoalText = Color(0xFF333333); // For headings (High contrast)
  static const Color slateGreyText = Color(0xFF666666); // For body text (Softer)
  static const Color errorCoral = Color(0xFFE57373);

  // --------------------------------------------------------------------------
  // LIGHT THEME CONFIGURATION
  // --------------------------------------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: creamBackground,
      colorScheme: const ColorScheme.light(
        primary: blushPink,
        onPrimary: surfaceWhite,
        secondary: champagneGold,
        onSecondary: charcoalText,
        surface: surfaceWhite,
        onSurface: charcoalText,
        error: errorCoral,
        onError: surfaceWhite,
      ),

      // ----------------------------------------------------------------------
      // TYPOGRAPHY (Clean & Elegant)
      // Note: For production, consider pairing 'google_fonts' (e.g., Playfair Display for headings, Montserrat for body)
      // ----------------------------------------------------------------------
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: charcoalText, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: charcoalText, fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: charcoalText, fontSize: 20, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: charcoalText, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: slateGreyText, fontSize: 14, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: surfaceWhite, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),

      // ----------------------------------------------------------------------
      // COMPONENT THEMES
      // ----------------------------------------------------------------------

      // App Bar: Clean, flat, borderless
      appBarTheme: const AppBarTheme(
        backgroundColor: creamBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: charcoalText),
        titleTextStyle: TextStyle(color: charcoalText, fontSize: 18, fontWeight: FontWeight.w600),
      ),

      // Buttons: Softly rounded, luxurious feel
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blushPink,
          foregroundColor: surfaceWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: roseGold,
          side: const BorderSide(color: blushPink, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Fields: Subtle borders, cream fill
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        hintStyle: const TextStyle(color: slateGreyText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: champagneGold.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: champagneGold.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blushPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorCoral, width: 1.5),
        ),
      ),

      // Cards: Soft shadows, modern aesthetic
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: charcoalText.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        elevation: 8,
        selectedItemColor: roseGold,
        unselectedItemColor: slateGreyText,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
    );
  }
}// Global UI Theme definitions (Blush pink, gold accents)
