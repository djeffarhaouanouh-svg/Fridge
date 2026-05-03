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
      _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
      _NavItem(icon: Icons.calendar_month_rounded, label: 'Plan', index: 1),
      _NavItem(icon: Icons.camera_alt_rounded, label: 'Scanner', index: 2),
      _NavItem(icon: Icons.person_rounded, label: 'Profil', index: 3),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              // background: rgba(255, 255, 255, 0.12)
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
              // border: 1px solid rgba(255, 255, 255, 0.2)
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              // box-shadow: 0 4px 20px rgba(0,0,0,0.1)
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // inset 0 1px 1px rgba(255,255,255,0.2) — inner top highlight
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                      gradient: LinearGradient(colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ]),
                    ),
                  ),
                ),
                // tabs
                Positioned.fill(
                  child: Row(
                    children: items.map((item) {
                      final isActive = selected == item.index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(selectedTabProvider.notifier).state = item.index,
                          behavior: HitTestBehavior.opaque,
                          child: _NavTab(item: item, isActive: isActive),
                        ),
                      );
                    }).toList(),
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

class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  const _NavTab({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 14 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 19,
                color: isActive ? AppTokens.coral : Colors.white.withOpacity(0.55),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;
  const _NavItem({required this.icon, required this.label, required this.index});
}
