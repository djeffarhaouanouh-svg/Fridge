import 'package:flutter/material.dart';

/// Design Tokens - identiques au prototype HTML
class AppTokens {
  // Colors
  static const Color bg = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color card = Color(0xFF222222);
  static const Color border = Color(0x12FFFFFF);
  static const Color text = Color(0xFFF5F0E8);
  static const Color muted = Color(0x73F5F0E8);
  static const Color accent = Color(0xFF82D28C);
  static const Color accentDim = Color(0x26825D28C);
  static const Color warm = Color(0xFFE8D5A3);
  static const Color red = Color(0xFFE07070);

  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Border Radius
  static const double radiusSm = 12.0;
  static const double radiusMd = 14.0;
  static const double radiusLg = 20.0;

  // Typography - Utilise Google Fonts
  static const String fontSyne = 'Syne';
  static const String fontDMSans = 'DM Sans';

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> accentGlow = [
    BoxShadow(
      color: accent.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}
