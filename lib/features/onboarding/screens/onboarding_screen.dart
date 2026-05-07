import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../profile/providers/profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _dietTiles = <_OptionTileData>[
    _OptionTileData(
      label: 'Sans produit laitier',
      icon: Icons.no_drinks_outlined,
      value: 'Sans lactose',
    ),
    _OptionTileData(
      label: 'Sans gluten',
      icon: Icons.grain_outlined,
      value: 'Sans gluten',
    ),
    _OptionTileData(
      label: 'Sans porc',
      icon: Icons.no_food_outlined,
      value: 'Sans porc',
    ),
    _OptionTileData(
      label: 'Végétalien\n(vegan)',
      icon: Icons.eco_outlined,
      value: 'Végétalien',
    ),
    _OptionTileData(
      label: 'Végétarien',
      icon: Icons.spa_outlined,
      value: 'Végétarien',
    ),
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

  static const _goalTiles = <_ObjectiveTileData>[
    _ObjectiveTileData(label: 'Perte de poids', icon: Icons.monitor_weight_outlined, value: CookingObjective.weightLoss),
    _ObjectiveTileData(label: 'Prise de masse', icon: Icons.fitness_center_outlined, value: CookingObjective.muscleGain),
    _ObjectiveTileData(label: 'Famille', icon: Icons.groups_outlined, value: CookingObjective.family),
    _ObjectiveTileData(label: 'Passion cuisine', icon: Icons.restaurant_menu_outlined, value: CookingObjective.passion),
  ];

  static const _levelTiles = <_LevelTileData>[
    _LevelTileData(label: 'Débutant', icon: Icons.looks_one_outlined, value: CookingLevel.beginner),
    _LevelTileData(label: 'Intermédiaire', icon: Icons.looks_two_outlined, value: CookingLevel.intermediate),
    _LevelTileData(label: 'Avancé', icon: Icons.looks_3_outlined, value: CookingLevel.advanced),
    _LevelTileData(label: 'Expert', icon: Icons.workspace_premium_outlined, value: CookingLevel.expert),
  ];

  void _next() {
    if (_page >= 3) {
      widget.onComplete();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);
    final bg = isDark ? const Color(0xFF151515) : AppTokens.paper;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final subtitleColor = isDark ? Colors.white70 : AppTokens.inkSoft;
    final lineBg = isDark ? Colors.white24 : AppTokens.hairline;
    final progress = (_page + 1) / 4;

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
                        color: AppTokens.coral,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      'Passer',
                      style: GoogleFonts.inter(
                        color: AppTokens.coral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (v) => setState(() => _page = v),
                children: [
                  _QuestionPage(
                    title: 'Objectif',
                    subtitle: 'Quel est votre objectif principal ?',
                    child: _SingleChoiceGrid<CookingObjective>(
                      options: _goalTiles
                          .map((tile) => _SelectableTile<CookingObjective>(
                                value: tile.value,
                                label: tile.label,
                                icon: tile.icon,
                              ))
                          .toList(),
                      selected: profile.objective,
                      onSelect: notifier.setObjective,
                    ),
                  ),
                  _QuestionPage(
                    title: 'Niveau de cuisine',
                    subtitle: 'Quel est votre niveau actuel ?',
                    child: _SingleChoiceGrid<CookingLevel>(
                      options: _levelTiles
                          .map((tile) => _SelectableTile<CookingLevel>(
                                value: tile.value,
                                label: tile.label,
                                icon: tile.icon,
                              ))
                          .toList(),
                      selected: profile.cookingLevel,
                      onSelect: notifier.setCookingLevel,
                    ),
                  ),
                  _QuestionPage(
                    title: 'Votre régime',
                    subtitle: 'Avez-vous un régime particulier ?',
                    child: _MultiChoiceGrid(
                      options: _dietTiles,
                      selected: profile.diets,
                      onToggle: notifier.toggleDiet,
                    ),
                  ),
                  _QuestionPage(
                    title: 'Votre cuisine',
                    subtitle: 'Quels sont vos équipements de cuisine ?',
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
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.coral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                    ),
                  ),
                  child: Text(
                    _page == 3 ? 'Terminer' : 'Suivant',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
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
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              height: 1.3,
              color: subtitleColor,
            ),
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
            color: selected ? AppTokens.coral.withValues(alpha: 0.45) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 45,
              color: selected ? AppTokens.coral : baseColor,
            ),
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

  const _OptionTileData({
    required this.label,
    required this.icon,
    required this.value,
  });
}

class _SelectableTile<T> {
  final T value;
  final String label;
  final IconData icon;

  const _SelectableTile({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class _ObjectiveTileData {
  final String label;
  final IconData icon;
  final CookingObjective value;

  const _ObjectiveTileData({
    required this.label,
    required this.icon,
    required this.value,
  });
}

class _LevelTileData {
  final String label;
  final IconData icon;
  final CookingLevel value;

  const _LevelTileData({
    required this.label,
    required this.icon,
    required this.value,
  });
}
