import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_tokens.dart';

class AppSplashScreen extends StatelessWidget {
  final String subtitle;

  const AppSplashScreen({
    super.key,
    this.subtitle = 'Préparation de ton espace cuisine...',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF151515) : AppTokens.paper;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final subtitleColor = isDark ? Colors.white70 : AppTokens.muted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'icon.js/farfalle.png',
                  width: 82,
                  height: 82,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fridge',
                  style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: AppTokens.coral,
                    strokeWidth: 2.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
