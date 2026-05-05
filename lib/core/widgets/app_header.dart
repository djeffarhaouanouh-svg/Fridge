import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_tokens.dart';

class AppHeader extends StatelessWidget {
  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final bool brand;

  const AppHeader({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.brand = false,
  });

  static const double _sideSlotWidth = 44;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: Row(
          children: [
            SizedBox(
              width: _sideSlotWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: leading,
              ),
            ),
            Expanded(
              child: Center(
                child: brand
                    ? const _BrandWordmark()
                    : (title == null
                        ? const SizedBox()
                        : Text(
                            title!,
                            style: GoogleFonts.fraunces(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.ink,
                            ),
                          )),
              ),
            ),
            SizedBox(
              width: _sideSlotWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: trailing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.kitchen_outlined, color: AppTokens.coral, size: 22),
        const SizedBox(width: 6),
        Text(
          'fridge·ai',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTokens.coral,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
