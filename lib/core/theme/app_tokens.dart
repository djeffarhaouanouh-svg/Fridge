import 'package:flutter/material.dart';

class AppTokens {
  // Inks (text)
  static const Color ink = Color(0xFF1A1410);
  static const Color inkSoft = Color(0xFF4A3F38);
  static const Color muted = Color(0xFF9A8D83);
  static const Color hairline = Color(0xFFE8DFD6);
  static const Color hairlineSoft = Color(0xFFF1EBE3);

  // Surfaces (papier chaud)
  static const Color paper = Color(0xFFFDFAF5);
  static const Color surface = Color(0xFFF7F1E8);
  static const Color surface2 = Color(0xFFF0E8DC);
  static const Color placeholder = Color(0xFFE0D4C2);
  static const Color placeholderDeep = Color(0xFFC9B9A3);

  // Coral Marmiton
  static const Color coral = Color(0xFFEE5C42);
  static const Color coralSoft = Color(0xFFFFE7DF);
  static const Color coralDeep = Color(0xFFD24228);

  // Apple iOS green (glass pills CTA principaux uniquement)
  static const Color iosGreen = Color(0xFF34C759);

  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Border radius
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 22.0;
  static const double radiusPill = 999.0;

  // Fonts
  static const String fontDisplay = 'Fraunces';
  static const String fontBody = 'Inter';

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> coralGlow = [
    BoxShadow(
      color: Color(0x73EE5C42),
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
  ];

  // Compat aliases — anciens noms dark-theme, à retirer écran par écran lors de la refonte
  static const Color bg = paper;
  static const Color card = surface;
  static const Color border = hairline;
  static const Color text = ink;
  static const Color accent = coral;
  static const Color accentDim = coralSoft;
  static const Color warm = surface2;
  static const Color red = Color(0xFFE07070);
}
