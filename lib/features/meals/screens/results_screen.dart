import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/meal_image.dart';
import '../../../core/widgets/glass_button.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';
import 'recipe_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Results Screen — Premium AI Experience
// ═══════════════════════════════════════════════════════════════════════════════

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with TickerProviderStateMixin {
  bool _analyzing = true;
  int _analysisStep = 0;
  int _visibleIngredients = 0;
  int _visibleRecipes = 0;
  bool _resultsVisible = false;

  static const _phrases = [
    'Analyse des aliments...',
    'Détection des ingrédients...',
    'Création de recettes personnalisées...',
    'Optimisation anti-gaspillage...',
  ];

  late final AnimationController _pulseCtrl;
  late final AnimationController _exitCtrl;
  late final Animation<double> _pulse;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulse = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitCtrl, curve: Curves.easeOut),
    );
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    for (int i = 0; i < _phrases.length; i++) {
      if (!mounted) return;
      setState(() => _analysisStep = i);
      await Future.delayed(const Duration(milliseconds: 1100));
    }
    _exitCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      _resultsVisible = true;
    });
    _revealIngredients();
  }

  Future<void> _revealIngredients() async {
    final scan = ref.read(latestScanIngredientsProvider);
    final all = ref.read(detectedIngredientsProvider);
    final list = scan.isNotEmpty ? scan : all;
    for (int i = 0; i < list.length; i++) {
      await Future.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() => _visibleIngredients = i + 1);
    }
    await Future.delayed(const Duration(milliseconds: 280));
    _revealRecipes();
  }

  Future<void> _revealRecipes() async {
    final scan = ref.read(latestScanMealsProvider);
    final all = ref.read(mealsProvider);
    final list = scan.isNotEmpty ? scan : all;
    for (int i = 0; i < list.length; i++) {
      await Future.delayed(const Duration(milliseconds: 170));
      if (!mounted) return;
      setState(() => _visibleRecipes = i + 1);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E0E) : AppTokens.paper,
      body: Stack(
        children: [
          _GradientBackground(isDark: isDark),
          if (!_analyzing)
            AnimatedOpacity(
              opacity: _resultsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              child: _ResultsContent(
                visibleIngredients: _visibleIngredients,
                visibleRecipes: _visibleRecipes,
              ),
            ),
          if (_analyzing)
            FadeTransition(
              opacity: _exitFade,
              child: _AiAnalysisOverlay(
                phrase: _phrases[_analysisStep],
                pulseAnim: _pulse,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Subtle gradient background ───────────────────────────────────────────────

class _GradientBackground extends StatelessWidget {
  final bool isDark;
  const _GradientBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0E0E0E), const Color(0xFF160B08)]
              : [AppTokens.paper, const Color(0xFFFFF5EE)],
        ),
      ),
    );
  }
}

// ── AI analysis overlay ──────────────────────────────────────────────────────

class _AiAnalysisOverlay extends StatelessWidget {
  final String phrase;
  final Animation<double> pulseAnim;
  final bool isDark;

  const _AiAnalysisOverlay({
    required this.phrase,
    required this.pulseAnim,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTokens.ink;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0E0E0E), const Color(0xFF1A0A06)]
              : [AppTokens.paper, const Color(0xFFFFF0E5)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing glowing orb
              ScaleTransition(
                scale: pulseAnim,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTokens.coral.withOpacity(0.22),
                        AppTokens.coral.withOpacity(0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.35, 0.65, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTokens.coral,
                        boxShadow: [
                          BoxShadow(
                            color: AppTokens.coral.withOpacity(0.55),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 52),

              // Animated phrase with crossfade + slide
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut),
                      ),
                      child: child,
                    ),
                  ),
                  child: Text(
                    phrase,
                    key: ValueKey(phrase),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'fridge·ai',
                style: GoogleFonts.fraunces(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.coral.withOpacity(0.8),
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 44),
              const _DotsIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wave dots loading indicator ──────────────────────────────────────────────

class _DotsIndicator extends StatefulWidget {
  const _DotsIndicator();

  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = ((_ctrl.value * 3 - i) % 3) / 3;
            final wave = math.sin(phase * math.pi).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Opacity(
                opacity: 0.3 + 0.7 * wave,
                child: Transform.scale(
                  scale: 0.6 + 0.4 * wave,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTokens.coral,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Results content ──────────────────────────────────────────────────────────

class _ResultsContent extends ConsumerWidget {
  final int visibleIngredients;
  final int visibleRecipes;

  const _ResultsContent({
    required this.visibleIngredients,
    required this.visibleRecipes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white70 : AppTokens.muted;

    final scanMeals = ref.watch(latestScanMealsProvider);
    final allMeals = ref.watch(mealsProvider);
    final meals = scanMeals.isNotEmpty ? scanMeals : allMeals;
    final scanIngredients = ref.watch(latestScanIngredientsProvider);
    final fridgeIngredients = ref.watch(detectedIngredientsProvider);
    final ingredients =
        scanIngredients.isNotEmpty ? scanIngredients : fridgeIngredients;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Icon(Icons.arrow_back_ios_new, size: 18, color: ink),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Voici ce que j\'ai détecté',
                      style: GoogleFonts.fraunces(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              children: [
                // Detected ingredients section
                if (ingredients.isNotEmpty) ...[
                  Text(
                    'DÉTECTÉS · ${ingredients.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.coral,
                      letterSpacing: 0.06 * 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...List.generate(
                        ingredients.length,
                        (i) => _AnimatedIngredientChip(
                          label: ingredients[i],
                          visible: visibleIngredients > i,
                          isDark: isDark,
                          ink: ink,
                        ),
                      ),
                      AnimatedOpacity(
                        opacity:
                            visibleIngredients >= ingredients.length ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 400),
                        child: GestureDetector(
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const _IngredientsEditorSheet(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            child: Text(
                              '+ Ajouter ou modifier',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],

                // Recipes title
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${meals.length} recettes pour ',
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: ink,
                          height: 1.2,
                        ),
                      ),
                      TextSpan(
                        text: 'ce soir',
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.coral,
                          fontStyle: FontStyle.italic,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Avec ce que tu as déjà',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 20),

                // Recipe cards
                ...List.generate(
                  meals.length,
                  (i) => _AnimatedRecipeCard(
                    meal: meals[i],
                    index: i,
                    visible: visibleRecipes > i,
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 32),

                // CTA — appears after all cards
                AnimatedOpacity(
                  opacity: visibleRecipes >= meals.length && meals.isNotEmpty
                      ? 1.0
                      : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: GlassButton(
                      label: 'Générer plus de recettes',
                      icon: Icons.auto_awesome,
                      color: GlassButtonColor.green,
                      size: GlassButtonSize.lg,
                      fullWidth: false,
                      onTap: () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated ingredient chip ─────────────────────────────────────────────────

class _AnimatedIngredientChip extends StatefulWidget {
  final String label;
  final bool visible;
  final bool isDark;
  final Color ink;

  const _AnimatedIngredientChip({
    required this.label,
    required this.visible,
    required this.isDark,
    required this.ink,
  });

  @override
  State<_AnimatedIngredientChip> createState() =>
      _AnimatedIngredientChipState();
}

class _AnimatedIngredientChipState extends State<_AnimatedIngredientChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.visible) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedIngredientChip old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1E1E1E) : AppTokens.surface;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
            border: Border.all(
              color: AppTokens.coral.withOpacity(0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTokens.coral.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppTokens.coral,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTokens.coral.withOpacity(0.55),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated recipe card ─────────────────────────────────────────────────────

class _AnimatedRecipeCard extends StatefulWidget {
  final Meal meal;
  final int index;
  final bool visible;
  final bool isDark;

  const _AnimatedRecipeCard({
    required this.meal,
    required this.index,
    required this.visible,
    required this.isDark,
  });

  @override
  State<_AnimatedRecipeCard> createState() => _AnimatedRecipeCardState();
}

class _AnimatedRecipeCardState extends State<_AnimatedRecipeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    if (widget.visible) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedRecipeCard old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.isDark ? Colors.white : AppTokens.ink;
    final muted = widget.isDark ? Colors.white70 : AppTokens.muted;
    final cardBg = widget.isDark ? const Color(0xFF1C1C1C) : Colors.white;
    final num = (widget.index + 1).toString().padLeft(2, '0');

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeScreen(
                  meal: widget.meal,
                  isGeneratedRecipe: true,
                ),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(widget.isDark ? 0.28 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppTokens.coral.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppTokens.radiusLg),
                      bottomLeft: Radius.circular(AppTokens.radiusLg),
                    ),
                    child: SizedBox(
                      width: 92,
                      height: 96,
                      child: MealImage(
                        photo: widget.meal.photo,
                        fallbackKey: widget.meal.title,
                      ),
                    ),
                  ),

                  // Info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Badge(
                                text: 'N°$num',
                                bg: AppTokens.coral.withOpacity(0.12),
                                fg: AppTokens.coral,
                              ),
                              const SizedBox(width: 6),
                              _Badge(
                                text: widget.meal.typeLabel,
                                bg: widget.isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : AppTokens.surface,
                                fg: muted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.meal.title,
                            style: GoogleFonts.fraunces(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: ink,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.schedule_outlined,
                                  size: 12, color: muted),
                              const SizedBox(width: 3),
                              Text(
                                widget.meal.time,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              _MetaDot(color: muted),
                              Text(
                                '${widget.meal.kcal} kcal',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              _MetaDot(color: muted),
                              Flexible(
                                child: Text(
                                  widget.meal.difficulty,
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Chevron
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: muted.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small shared helpers ─────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Badge({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MetaDot extends StatelessWidget {
  final Color color;
  const _MetaDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: color.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Bottom sheet édition ingrédients ────────────────────────────────────────

class _IngredientsEditorSheet extends ConsumerStatefulWidget {
  const _IngredientsEditorSheet();

  @override
  ConsumerState<_IngredientsEditorSheet> createState() =>
      _IngredientsEditorSheetState();
}

class _IngredientsEditorSheetState
    extends ConsumerState<_IngredientsEditorSheet> {
  final _addCtrl = TextEditingController();
  final _editCtrl = TextEditingController();
  int? _editingIndex;

  @override
  void dispose() {
    _addCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  void _startEdit(int index, String current) {
    setState(() {
      _editingIndex = index;
      _editCtrl.text = current;
    });
  }

  Future<void> _saveEdit(int index) async {
    final val = _editCtrl.text.trim();
    if (val.isNotEmpty) {
      final list = List<String>.from(ref.read(latestScanIngredientsProvider));
      list[index] = val;
      ref.read(latestScanIngredientsProvider.notifier).state = list;
    }
    setState(() => _editingIndex = null);
  }

  Future<void> _delete(int index) async {
    final list = List<String>.from(ref.read(latestScanIngredientsProvider));
    list.removeAt(index);
    ref.read(latestScanIngredientsProvider.notifier).state = list;
    if (_editingIndex == index) setState(() => _editingIndex = null);
  }

  Future<void> _addIngredient() async {
    final val = _addCtrl.text.trim();
    if (val.isEmpty) return;
    final list = List<String>.from(ref.read(latestScanIngredientsProvider));
    list.add(val.toLowerCase());
    ref.read(latestScanIngredientsProvider.notifier).state = list;
    _addCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(latestScanIngredientsProvider);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTokens.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Modifier les ingrédients',
              style: GoogleFonts.fraunces(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTokens.ink,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: ingredients.length,
                itemBuilder: (_, i) {
                  if (_editingIndex == i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _editCtrl,
                              autofocus: true,
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppTokens.ink),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: AppTokens.coral),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppTokens.coral, width: 1.5),
                                ),
                              ),
                              onSubmitted: (_) => _saveEdit(i),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _saveEdit(i),
                            child: const Icon(Icons.check_circle,
                                size: 22, color: AppTokens.coral),
                          ),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                              color: AppTokens.ink, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(ingredients[i],
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppTokens.ink)),
                        ),
                        GestureDetector(
                          onTap: () => _startEdit(i, ingredients[i]),
                          child: Icon(Icons.edit_outlined,
                              size: 18, color: AppTokens.muted),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => _delete(i),
                          child: const Icon(Icons.close,
                              size: 18, color: AppTokens.coral),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: AppTokens.hairlineSoft),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCtrl,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppTokens.ink),
                    decoration: InputDecoration(
                      hintText: 'ajoute un ingrédient que je n\'ai pas détecté',
                      hintStyle: GoogleFonts.inter(
                          color: AppTokens.muted, fontSize: 14),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                GestureDetector(
                  onTap: _addIngredient,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                        color: AppTokens.coral, shape: BoxShape.circle),
                    child:
                        const Icon(Icons.add, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppTokens.ink,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                ),
                child: Center(
                  child: Text(
                    'Valider',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
