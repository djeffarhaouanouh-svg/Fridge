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

  static const _allergyOptions = [
    'Gluten',
    'Lactose',
    'Noix',
    'Œufs',
    'Fruits de mer',
    'Soja',
  ];
  static const _dietOptions = [
    'Végétarien',
    'Végétalien',
    'Halal',
    'Keto',
    'Sans gluten',
    'Sans lactose',
  ];
  static const _kitchenOptions = [
    'Micro-ondes',
    'Four',
    'Plaques de cuisson',
    'Friteuse',
    'Mixeur',
    'Robot cuiseur',
    'Air-fryer',
  ];

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
      return;
    }
    widget.onComplete();
  }

  void _back() {
    if (_page == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 240),
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
    final textColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white70 : AppTokens.muted;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : AppTokens.surface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Personnalise ton expérience',
                      style: GoogleFonts.fraunces(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onComplete,
                    child: Text(
                      'Passer',
                      style: GoogleFonts.inter(
                        color: AppTokens.coral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Réponds à ces questions pour des recettes vraiment adaptées.',
                  style: GoogleFonts.inter(fontSize: 13.5, color: mutedColor),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 26 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? AppTokens.coral
                          : (isDark ? Colors.white24 : AppTokens.hairline),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Étape ${_page + 1}/3',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _OnboardingPage(
                    cardBg: cardBg,
                    children: [
                      _SingleChoiceQuestion<CookingObjective>(
                        title: 'Objectif',
                        icon: Icons.flag_outlined,
                        selected: profile.objective,
                        options: const {
                          CookingObjective.weightLoss: 'Perte de poids',
                          CookingObjective.muscleGain: 'Prise de masse',
                          CookingObjective.family: 'Famille',
                          CookingObjective.passion: 'Passion cuisine',
                        },
                        onSelect: (value) => notifier.setObjective(value),
                      ),
                      _SingleChoiceQuestion<CookingLevel>(
                        title: 'Niveau de cuisine',
                        icon: Icons.auto_awesome_outlined,
                        selected: profile.cookingLevel,
                        options: const {
                          CookingLevel.beginner: 'Débutant',
                          CookingLevel.intermediate: 'Intermédiaire',
                          CookingLevel.advanced: 'Avancé',
                          CookingLevel.expert: 'Expert',
                        },
                        onSelect: (value) => notifier.setCookingLevel(value),
                      ),
                    ],
                  ),
                  _OnboardingPage(
                    cardBg: cardBg,
                    children: [
                      _MultiChoiceQuestion(
                        title: 'Allergies',
                        icon: Icons.warning_amber_outlined,
                        selected: profile.allergies,
                        options: _allergyOptions,
                        onToggle: notifier.toggleAllergy,
                      ),
                      _MultiChoiceQuestion(
                        title: 'Régime',
                        icon: Icons.restaurant_menu_outlined,
                        selected: profile.diets,
                        options: _dietOptions,
                        onToggle: notifier.toggleDiet,
                      ),
                    ],
                  ),
                  _OnboardingPage(
                    cardBg: cardBg,
                    children: [
                      _MultiChoiceQuestion(
                        title: 'Votre cuisine',
                        icon: Icons.kitchen_outlined,
                        selected: profile.kitchenEquipments,
                        options: _kitchenOptions,
                        onToggle: notifier.toggleKitchenEquipment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _page == 0 ? null : _back,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? Colors.white24 : AppTokens.hairline,
                        ),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                      child: Text(
                        'Retour',
                        style: GoogleFonts.inter(
                          color: _page == 0 ? mutedColor : textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.coral,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        ),
                      ),
                      child: Text(
                        _page == 2 ? 'Terminer' : 'Continuer',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final List<Widget> children;
  final Color cardBg;

  const _OnboardingPage({required this.children, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white12
                : AppTokens.hairline,
          ),
        ),
        child: children[i],
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: children.length,
    );
  }
}

class _SingleChoiceQuestion<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final T? selected;
  final Map<T, String> options;
  final ValueChanged<T> onSelect;

  const _SingleChoiceQuestion({
    required this.title,
    required this.icon,
    required this.selected,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white70 : AppTokens.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: muted),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final isSelected = selected == entry.key;
            return ChoiceChip(
              selected: isSelected,
              label: Text(entry.value),
              onSelected: (_) => onSelect(entry.key),
              selectedColor: AppTokens.coralSoft,
              backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? AppTokens.coral : textColor,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTokens.coral
                    : (isDark ? Colors.white24 : AppTokens.hairline),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _MultiChoiceQuestion extends StatelessWidget {
  final String title;
  final IconData icon;
  final Set<String> selected;
  final List<String> options;
  final ValueChanged<String> onToggle;

  const _MultiChoiceQuestion({
    required this.title,
    required this.icon,
    required this.selected,
    required this.options,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white70 : AppTokens.muted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: muted),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((item) {
            final isSelected = selected.contains(item);
            return FilterChip(
              selected: isSelected,
              label: Text(item),
              onSelected: (_) => onToggle(item),
              selectedColor: AppTokens.coralSoft,
              checkmarkColor: AppTokens.coral,
              backgroundColor: isDark ? const Color(0xFF262626) : Colors.white,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? AppTokens.coral : textColor,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTokens.coral
                    : (isDark ? Colors.white24 : AppTokens.hairline),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
