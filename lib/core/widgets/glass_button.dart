import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_tokens.dart';

enum GlassButtonColor { green, coral, light, dark }
enum GlassButtonSize { sm, md, lg }

/// Bouton liquid-glass Apple-style : backdrop blur + bordure 0.5px + highlight intérieur.
class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final GlassButtonColor color;
  final GlassButtonSize size;
  final VoidCallback? onTap;
  final bool fullWidth;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.color = GlassButtonColor.green,
    this.size = GlassButtonSize.md,
    this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = _tint(color);
    final h = switch (size) {
      GlassButtonSize.sm => 36.0,
      GlassButtonSize.md => 44.0,
      GlassButtonSize.lg => 52.0,
    };
    final fs = switch (size) {
      GlassButtonSize.sm => 12.5,
      GlassButtonSize.md => 14.0,
      GlassButtonSize.lg => 15.0,
    };

    // Le libellé doit rester un enfant non-[Positioned] pour que IntrinsicWidth
    // mesure correctement la pill (sinon largeur ~0 → bouton invisible).
    final inner = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(h / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: t.bg),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              border: Border.all(color: t.border, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: t.shine,
                  blurRadius: 0,
                  offset: const Offset(0.8, 0.8),
                  spreadRadius: -0.5,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fs + 2, color: t.text),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: fs,
                  fontWeight: FontWeight.w600,
                  color: t.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final sized = SizedBox(height: h, width: fullWidth ? double.infinity : null, child: inner);
    return GestureDetector(
      onTap: onTap,
      child: fullWidth ? sized : IntrinsicWidth(child: sized),
    );
  }

  _Tint _tint(GlassButtonColor c) => switch (c) {
        GlassButtonColor.green => const _Tint(
            bg: Color(0x3334C759),
            border: Color(0x8C34C759),
            text: Color(0xFF1A6B2E),
            shine: Color(0x80FFFFFF),
          ),
        GlassButtonColor.coral => const _Tint(
            bg: Color(0x2EEE5C42),
            border: Color(0x80EE5C42),
            text: AppTokens.coralDeep,
            shine: Color(0x8CFFFFFF),
          ),
        GlassButtonColor.light => _Tint(
            bg: Colors.white.withOpacity(0.7),
            border: Colors.black.withOpacity(0.08),
            text: AppTokens.ink,
            shine: Colors.white.withOpacity(0.85),
          ),
        GlassButtonColor.dark => _Tint(
            bg: const Color(0x99141414),
            border: Colors.white.withOpacity(0.18),
            text: Colors.white,
            shine: Colors.white.withOpacity(0.18),
          ),
      };
}

class _Tint {
  final Color bg, border, text, shine;
  const _Tint({required this.bg, required this.border, required this.text, required this.shine});
}
