import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../profile/providers/profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final ValueChanged<String> onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final _nameCtrl = TextEditingController();
  int _page = 0;

  static const _goalTiles = <_ObjectiveTileData>[
    _ObjectiveTileData(label: 'Perte de poids', icon: Icons.monitor_weight_outlined, value: CookingObjective.weightLoss),
    _ObjectiveTileData(label: 'Prise de masse', icon: Icons.fitness_center_outlined, value: CookingObjective.muscleGain),
    _ObjectiveTileData(label: 'Manger sainement', icon: Icons.eco_outlined, value: CookingObjective.healthy),
    _ObjectiveTileData(label: 'Apprendre à cuisiner', icon: Icons.school_outlined, value: CookingObjective.learn),
    _ObjectiveTileData(label: 'Garder la ligne', icon: Icons.straighten_outlined, value: CookingObjective.maintain),
  ];

  static const _kitchenTiles = <_OptionTileData>[
    _OptionTileData(label: 'Micro-ondes', icon: Icons.microwave_outlined, value: 'Micro-ondes'),
    _OptionTileData(label: 'Four', icon: Icons.local_fire_department_outlined, value: 'Four'),
    _OptionTileData(label: 'Plaques de\ncuisson', icon: Icons.grid_4x4_outlined, value: 'Plaques de cuisson'),
    _OptionTileData(label: 'Friteuse', icon: Icons.lunch_dining_outlined, value: 'Friteuse'),
    _OptionTileData(label: 'Mixeur', icon: Icons.blender_outlined, value: 'Mixeur'),
    _OptionTileData(label: 'Robot cuiseur', icon: Icons.soup_kitchen_outlined, value: 'Robot cuiseur'),
    _OptionTileData(label: 'Air-fryer', icon: Icons.kitchen_outlined, value: 'Air-fryer'),
  ];

  void _next() {
    if (_page == 0 && _nameCtrl.text.trim().isEmpty) return;
    if (_page >= 2) {
      widget.onComplete(_nameCtrl.text.trim());
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_page == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);
    final bg = isDark ? const Color(0xFF151515) : AppTokens.paper;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final subtitleColor = isDark ? Colors.white70 : AppTokens.inkSoft;
    final lineBg = isDark ? Colors.white24 : AppTokens.hairline;
    final progress = (_page + 1) / 3;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _page == 0 ? null : _back,
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: _page == 0 ? subtitleColor.withValues(alpha: 0.45) : titleColor,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: lineBg,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (v) => setState(() => _page = v),
                children: [
                  // ── Page 0 : Prénom ──────────────────────────────────
                  _QuestionPage(
                    title: 'Bonjour !',
                    subtitle: 'Comment tu veux qu\'on t\'appelle ?',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _next(),
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.fraunces(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ton prénom…',
                          hintStyle: GoogleFonts.fraunces(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white24 : AppTokens.hairline,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Page 1 : Objectif ────────────────────────────────
                  _QuestionPage(
                    title: 'Objectif',
                    subtitle: 'Quel est ton objectif principal ?',
                    child: _SingleChoiceGrid<CookingObjective>(
                      options: _goalTiles
                          .map((t) => _SelectableTile<CookingObjective>(
                                value: t.value,
                                label: t.label,
                                icon: t.icon,
                              ))
                          .toList(),
                      selected: profile.objective,
                      onSelect: notifier.setObjective,
                    ),
                  ),

                  // ── Page 2 : Votre cuisine ───────────────────────────
                  _QuestionPage(
                    title: 'Ta cuisine',
                    subtitle: 'Quels équipements tu as ?',
                    child: _MultiChoiceGrid(
                      options: _kitchenTiles,
                      selected: profile.kitchenEquipments,
                      onToggle: notifier.toggleKitchenEquipment,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_page == 0 && _nameCtrl.text.trim().isEmpty) ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: primary.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                  ),
                  child: Text(
                    _page == 2 ? 'Terminer' : 'Suivant',
                    style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _QuestionPage({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final subtitleColor = isDark ? Colors.white70 : AppTokens.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fraunces(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 18, height: 1.3, color: subtitleColor),
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SingleChoiceGrid<T> extends StatelessWidget {
  final List<_SelectableTile<T>> options;
  final T? selected;
  final ValueChanged<T> onSelect;

  const _SingleChoiceGrid({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (_, i) {
        final item = options[i];
        final isSelected = selected == item.value;
        return _OptionTile(
          label: item.label,
          icon: item.icon,
          selected: isSelected,
          onTap: () => onSelect(item.value),
        );
      },
    );
  }
}

class _MultiChoiceGrid extends StatelessWidget {
  final List<_OptionTileData> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _MultiChoiceGrid({
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (_, i) {
        final item = options[i];
        final isSelected = selected.contains(item.value);
        return _OptionTile(
          label: item.label,
          icon: item.icon,
          selected: isSelected,
          onTap: () => onToggle(item.value),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final baseColor = isDark ? Colors.white70 : const Color(0xFF66707A);
    final textColor = isDark ? Colors.white : AppTokens.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primary.withValues(alpha: 0.45) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 45, color: selected ? primary : baseColor),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTileData {
  final String label;
  final IconData icon;
  final String value;

  const _OptionTileData({required this.label, required this.icon, required this.value});
}

class _SelectableTile<T> {
  final T value;
  final String label;
  final IconData icon;

  const _SelectableTile({required this.value, required this.label, required this.icon});
}

class _ObjectiveTileData {
  final String label;
  final IconData icon;
  final CookingObjective value;

  const _ObjectiveTileData({required this.label, required this.icon, required this.value});
}
