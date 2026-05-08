import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_tokens.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class BottomNav extends ConsumerWidget {
  final bool popRouteFirst;
  const BottomNav({super.key, this.popRouteFirst = false});

  static const _tabIndices = [0, 1, 3];
  static const _tabIcons = [
    Icons.home_rounded,
    Icons.calendar_month_rounded,
    Icons.person_rounded,
  ];

  void _navigate(BuildContext context, WidgetRef ref, int index) {
    if (popRouteFirst && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    ref.read(selectedTabProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 8),
      child: Row(
        children: [
          // ── Glass pill (3 tabs) ──────────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(3, (i) {
                      final tabIdx = _tabIndices[i];
                      final isActive = selected == tabIdx;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _navigate(context, ref, tabIdx),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOutCubic,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Icon(
                                _tabIcons[i],
                                size: 20,
                                color: isActive
                                    ? AppTokens.coral
                                    : Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ── Camera button ────────────────────────────────────────
          GestureDetector(
            onTap: () => _navigate(context, ref, 2),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTokens.coral.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
