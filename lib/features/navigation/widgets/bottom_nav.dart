import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    final items = [
      _NavTab(icon: Icons.home_outlined, label: 'Home', index: 0),
      _NavTab(icon: Icons.calendar_month_outlined, label: 'Plan', index: 1),
      _NavTab(icon: Icons.camera_alt_outlined, label: 'Scanner', index: 2),
      _NavTab(icon: Icons.person_outline, label: 'Profil', index: 3),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: items.map((tab) {
                final isActive = selected == tab.index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(selectedTabProvider.notifier).state = tab.index,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: isActive
                            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 7)
                            : const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withOpacity(0.45)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab.icon, size: 18, color: AppTokens.coral),
                            if (isActive) ...[
                              const SizedBox(width: 6),
                              Text(
                                tab.label,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.ink,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final int index;
  const _NavTab({required this.icon, required this.label, required this.index});
}
