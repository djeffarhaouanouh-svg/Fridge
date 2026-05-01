import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider pour gérer l'onglet actif
final selectedTabProvider = StateProvider<int>((ref) => 0);

class BottomNav extends ConsumerWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);

    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: AppTokens.bg.withOpacity(0.92),
        border: Border(
          top: BorderSide(
            color: AppTokens.border,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.camera_alt_outlined,
              label: 'Scanner',
              index: 0,
              isActive: selectedTab == 0,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
            ),
            _NavItem(
              icon: Icons.restaurant_outlined,
              label: 'Repas',
              index: 1,
              isActive: selectedTab == 1,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
            ),
            _NavItem(
              icon: Icons.calendar_month_outlined,
              label: 'Plan',
              index: 2,
              isActive: selectedTab == 2,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profil',
              index: 3,
              isActive: selectedTab == 3,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppTokens.accent : AppTokens.muted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTokens.accent : AppTokens.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
