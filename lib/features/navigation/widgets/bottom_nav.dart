import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_tokens.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTabProvider);
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    const icons = [
      Icons.home_rounded,
      Icons.calendar_month_rounded,
      Icons.camera_alt_rounded,
      Icons.person_rounded,
    ];
    const count = 4;
    const pillW = 48.0;
    const pillH = 36.0;
    const navH = 60.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabW = constraints.maxWidth / count;
              final pillLeft = selected * tabW + (tabW - pillW) / 2;

              return Container(
                height: navH,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
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
                    // Top inner highlight
                    Positioned(
                      top: 0, left: 0, right: 0,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                          gradient: LinearGradient(colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.0),
                          ]),
                        ),
                      ),
                    ),

                    // Sliding pill — un seul widget qui se déplace
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOutCubic,
                      left: pillLeft,
                      top: (navH - pillH) / 2,
                      width: pillW,
                      height: pillH,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    // Icônes
                    Positioned.fill(
                      child: Row(
                        children: List.generate(count, (i) {
                          final isActive = i == selected;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  ref.read(selectedTabProvider.notifier).state = i,
                              behavior: HitTestBehavior.opaque,
                              child: Center(
                                child: TweenAnimationBuilder<Color?>(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOutCubic,
                                  tween: ColorTween(
                                    begin: isActive
                                        ? Colors.white.withValues(alpha: 0.55)
                                        : AppTokens.coral,
                                    end: isActive
                                        ? AppTokens.coral
                                        : Colors.white.withValues(alpha: 0.55),
                                  ),
                                  builder: (_, color, __) => Icon(
                                    icons[i],
                                    size: 20,
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
    );
  }
}
