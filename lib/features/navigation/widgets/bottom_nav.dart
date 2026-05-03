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
      height: 72,
      decoration: BoxDecoration(
        color: AppTokens.paper.withOpacity(0.95),
        border: Border(top: BorderSide(color: AppTokens.hairline, width: 0.5)),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            index: 0,
            active: selected == 0,
            onTap: () => ref.read(selectedTabProvider.notifier).state = 0,
          ),
          _NavItem(
            icon: Icons.calendar_month_outlined,
            label: 'Plan semaine',
            index: 1,
            active: selected == 1,
            onTap: () => ref.read(selectedTabProvider.notifier).state = 1,
          ),
          _NavItem(
            icon: Icons.camera_alt_outlined,
            label: 'Scanner',
            index: 2,
            active: selected == 2,
            onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profil',
            index: 3,
            active: selected == 3,
            onTap: () => ref.read(selectedTabProvider.notifier).state = 3,
          ),
        ],
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
