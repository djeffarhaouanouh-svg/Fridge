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

    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: AppTokens.paper.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppTokens.hairline, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            _NavItem(
              icon: Icons.restaurant_menu_outlined,
              label: 'Recettes',
              index: 0,
              active: selected == 0,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
            ),
            _NavItem(
              icon: Icons.calendar_month_outlined,
              label: 'Plan',
              index: 1,
              active: selected == 1,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
            ),
            _ScannerFab(
              onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
            ),
            _NavItem(
              icon: Icons.favorite_border,
              label: 'Favoris',
              index: 3,
              active: selected == 3,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profil',
              index: 4,
              active: selected == 4,
              onTap: () => ref.read(selectedTabProvider.notifier).state = 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScannerFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, -34),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTokens.coral,
                shape: BoxShape.circle,
                border: Border.all(color: AppTokens.paper, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTokens.coral.withOpacity(0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = active ? AppTokens.coral : AppTokens.muted;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
