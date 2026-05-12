import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../profile/providers/profile_provider.dart';
import '../../subscription/subscription_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final ValueChanged<String> onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  int _page = 0;
  String? _gender; // 'homme' or 'femme'

  // Total pages: 0=Prénom, 1=Intro poids, 2=Objectif, 3=Genre, 4=Âge, 5=Poids, 6=Poids cible, 7=Cuisine
  static const _totalPages = 8;

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

  bool get _canProceed {
    switch (_page) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty;
      case 3:
        return _gender != null;
      case 4:
        final age = int.tryParse(_ageCtrl.text);
        return age != null && age >= 10 && age <= 120;
      case 5:
        final w = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
        return w != null && w >= 20 && w <= 300;
      case 6:
        final tw = double.tryParse(_targetWeightCtrl.text.replaceAll(',', '.'));
        return tw != null && tw >= 20 && tw <= 300;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (!_canProceed) return;

    if (_page >= _totalPages - 1) {
      await _saveBodyDataAndCalories();
      final name = _nameCtrl.text.trim();
      await AuthService.autoRegister(name);
      if (!mounted) return;
      ref.read(authStateProvider.notifier).state = true;
      await PurchaseService.identifyCurrentUser();
      if (!mounted) return;

      final usePaywall = !kIsWeb &&
          (Platform.isAndroid || Platform.isIOS);

      if (!usePaywall) {
        widget.onComplete(name);
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => SubscriptionScreen(
            onAccessGranted: () => widget.onComplete(name),
            onSkip: () => widget.onComplete(name),
          ),
        ),
      );
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

  Future<void> _saveBodyDataAndCalories() async {
    await ref.read(userProfileProvider.notifier).setBodyData(
      gender: _gender ?? 'homme',
      age: int.tryParse(_ageCtrl.text) ?? 25,
      weight: double.tryParse(_weightCtrl.text.replaceAll(',', '.')) ?? 70.0,
      targetWeight: double.tryParse(_targetWeightCtrl.text.replaceAll(',', '.')) ?? 70.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
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
    final progress = (_page + 1) / _totalPages;

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
                    subtitle: 'Comment aimeriez-vous qu\'on vous appelle ?',
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

                  // ── Page 1 : Intro gestion du poids ──────────────────
                  const _OnboardingWeightPrinciplesPage(),

                  // ── Page 2 : Objectif ────────────────────────────────
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

                  // ── Page 3 : Genre ───────────────────────────────────
                  _QuestionPage(
                    title: 'Genre',
                    subtitle: 'Tu es…',
                    child: _GenderPicker(
                      selected: _gender,
                      onSelect: (v) => setState(() => _gender = v),
                    ),
                  ),

                  // ── Page 4 : Âge ─────────────────────────────────────
                  _QuestionPage(
                    title: 'Âge',
                    subtitle: 'Tu as quel âge ?',
                    child: _NumberInputField(
                      controller: _ageCtrl,
                      hint: 'Ton âge…',
                      suffix: 'ans',
                      onChanged: () => setState(() {}),
                      onSubmitted: _next,
                    ),
                  ),

                  // ── Page 5 : Poids actuel ────────────────────────────
                  _QuestionPage(
                    title: 'Quel est votre poids actuel ?',
                    subtitle:
                        'Ce n\'est pas grave si ce n\'est pas exact. Vous pourrez modifier votre poids de départ plus tard.',
                    child: _NumberInputField(
                      controller: _weightCtrl,
                      hint: 'Ton poids…',
                      suffix: 'kg',
                      decimal: true,
                      onChanged: () => setState(() {}),
                      onSubmitted: _next,
                    ),
                  ),

                  // ── Page 6 : Poids cible ─────────────────────────────
                  _QuestionPage(
                    title: 'Objectif',
                    subtitle: 'Quel est ton poids cible ?',
                    child: _NumberInputField(
                      controller: _targetWeightCtrl,
                      hint: 'Poids visé…',
                      suffix: 'kg',
                      decimal: true,
                      onChanged: () => setState(() {}),
                      onSubmitted: _next,
                    ),
                  ),

                  // ── Page 7 : Ta cuisine ───────────────────────────────
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
                  onPressed: _canProceed ? _next : null,
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
                    _page == _totalPages - 1
                        ? 'Terminer'
                        : (_page == 1 ? 'D\'accord !' : 'Suivant'),
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

// ── Gender picker ─────────────────────────────────────────────────────────────

class _GenderPicker extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _GenderPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        _GenderTile(
          label: 'Homme',
          icon: Icons.male_rounded,
          value: 'homme',
          selected: selected == 'homme',
          primary: primary,
          isDark: isDark,
          onTap: () => onSelect('homme'),
        ),
        const SizedBox(width: 16),
        _GenderTile(
          label: 'Femme',
          icon: Icons.female_rounded,
          value: 'femme',
          selected: selected == 'femme',
          primary: primary,
          isDark: isDark,
          onTap: () => onSelect('femme'),
        ),
      ],
    );
  }
}

class _GenderTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _GenderTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? Colors.white54 : const Color(0xFF66707A);
    final textColor = isDark ? Colors.white : AppTokens.ink;
    final bg = selected
        ? primary.withValues(alpha: 0.1)
        : (isDark ? const Color(0xFF1E1E1E) : AppTokens.surface);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 130,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? primary.withValues(alpha: 0.6) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 52, color: selected ? primary : baseColor),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? primary : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Number input field ────────────────────────────────────────────────────────

class _NumberInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final bool decimal;
  final VoidCallback onChanged;
  final Future<void> Function() onSubmitted;

  const _NumberInputField({
    required this.controller,
    required this.hint,
    required this.suffix,
    this.decimal = false,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white54 : AppTokens.muted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: decimal
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              inputFormatters: [
                if (decimal)
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                else
                  FilteringTextInputFormatter.digitsOnly,
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmitted(),
              onChanged: (_) => onChanged(),
              style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
              decoration: InputDecoration(
                hintText: hint,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              suffix,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Intro « gestion du poids » (après prénom) ─────────────────────────────────

class _OnboardingWeightPrinciplesPage extends StatelessWidget {
  const _OnboardingWeightPrinciplesPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final bodyColor = isDark ? Colors.white70 : AppTokens.inkSoft;
    final chipBg = isDark ? const Color(0xFF1E1E1E) : AppTokens.surface;
    final chipBorder = isDark ? Colors.white12 : AppTokens.hairline;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Center(
              child: Image.asset(
                'assets/images/etape-2.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 12,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion saine et durable du poids',
                    style: GoogleFonts.fraunces(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PrincipleBullet(
                    icon: Icons.emoji_events_rounded,
                    text:
                        'Un suivi facile favorise la régularité. La régularité entraîne des résultats.',
                    primary: primary,
                    chipBg: chipBg,
                    chipBorder: chipBorder,
                    bodyColor: bodyColor,
                  ),
                  const SizedBox(height: 16),
                  _PrincipleBullet(
                    icon: Icons.home_rounded,
                    text:
                        'Le suivi des calories, de la consommation d\'eau, du sport et des macros regroupé à un seul endroit facilite la création d\'habitudes saines.',
                    primary: primary,
                    chipBg: chipBg,
                    chipBorder: chipBorder,
                    bodyColor: bodyColor,
                  ),
                  const SizedBox(height: 16),
                  _PrincipleBullet(
                    icon: Icons.track_changes_rounded,
                    text:
                        'Pour fixer vos objectifs avec précision, nous aimerions en savoir un peu plus sur vous.',
                    primary: primary,
                    chipBg: chipBg,
                    chipBorder: chipBorder,
                    bodyColor: bodyColor,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrincipleBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color primary;
  final Color chipBg;
  final Color chipBorder;
  final Color bodyColor;

  const _PrincipleBullet({
    required this.icon,
    required this.text,
    required this.primary,
    required this.chipBg,
    required this.chipBorder,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: chipBg,
            shape: BoxShape.circle,
            border: Border.all(color: chipBorder),
          ),
          child: Icon(icon, size: 22, color: primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: bodyColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared page shell ─────────────────────────────────────────────────────────

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

// ── Grid components ───────────────────────────────────────────────────────────

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

// ── Data classes ───────────────────────────────────────────────────────────────

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
