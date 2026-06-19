import 'package:flutter/material.dart';

abstract final class AppShadows {
  // Light Theme Shadows
  static const List<BoxShadow> lightSm = [
    BoxShadow(
      color: Color(0x0C000000), // 5% black
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> lightMd = [
    BoxShadow(
      color: Color(0x14000000), // 8% black
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> lightLg = [
    BoxShadow(
      color: Color(0x1A000000), // 10% black
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> lightXl = [
    BoxShadow(
      color: Color(0x26000000), // 15% black
      offset: Offset(0, 24),
      blurRadius: 48,
      spreadRadius: -12,
    ),
  ];

  // Dark Theme Shadows (more subtle, often using primary tint or deeper black)
  static const List<BoxShadow> darkSm = [
    BoxShadow(
      color: Color(0x80000000), // 50% black
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> darkMd = [
    BoxShadow(
      color: Color(0x99000000), // 60% black
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];

  static const List<BoxShadow> darkLg = [
    BoxShadow(
      color: Color(0xB3000000), // 70% black
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];
  
  // Glowing shadow for active/primary elements
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x402563EB), // 25% primary
      offset: Offset(0, 8),
      blurRadius: 16,
      spreadRadius: -4,
    ),
  ];
}
