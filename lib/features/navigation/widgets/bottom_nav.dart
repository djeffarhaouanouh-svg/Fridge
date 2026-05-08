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

  static const _pillW = 50.0;
  static const _pillH = 34.0;
  static const _navH = 56.0;

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
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Glass pill (3 tabs) ──────────────────────────────────
          SizedBox(
            width: 250,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tabW = constraints.maxWidth / 3;
                    // trouve l'index visuel du tab actif (0,1,2) ou -1 si caméra active
                    final visualIdx = _tabIndices.indexOf(selected);
                    final pillLeft = visualIdx >= 0
                        ? visualIdx * tabW + (tabW - _pillW) / 2
                        : -_pillW;

                    return Container(
                      height: _navH,
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
                      child: Stack(
                        children: [
                          // Top highlight
                          Positioned(
                            top: 0, left: 0, right: 0,
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(999)),
                                gradient: LinearGradient(colors: [
                                  Colors.white.withValues(alpha: 0.2),
                                  Colors.white.withValues(alpha: 0.0),
                                ]),
                              ),
                            ),
                          ),
                          // Sliding pill
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                            left: pillLeft,
                            top: (_navH - _pillH) / 2,
                            width: _pillW,
                            height: _pillH,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          // Icons
                          Positioned.fill(
                            child: Row(
                              children: List.generate(3, (i) {
                                final tabIdx = _tabIndices[i];
                                final isActive = selected == tabIdx;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        _navigate(context, ref, tabIdx),
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: TweenAnimationBuilder<Color?>(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeInOutCubic,
                                        tween: ColorTween(
                                          begin: isActive
                                              ? Colors.white
                                                  .withValues(alpha: 0.55)
                                              : AppTokens.coral,
                                          end: isActive
                                              ? AppTokens.coral
                                              : Colors.white
                                                  .withValues(alpha: 0.55),
                                        ),
                                        builder: (_, color, __) => Icon(
                                          _tabIcons[i],
                                          size: 19,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
