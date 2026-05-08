import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/services/elevenlabs_tts_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/recipe_ids.dart';
import '../../../core/utils/ingredient_category.dart';
import '../../../core/services/fridge_sync.dart';
import '../../../core/widgets/meal_image.dart';
import '../../meals/providers/meals_provider.dart';
import '../../navigation/widgets/bottom_nav.dart';
import '../models/meal.dart';

// ─── Fiche recette ─────────────────────────────────────────────────────────

class RecipeScreen extends ConsumerWidget {
  final Meal meal;
  final bool fromPlan;
  const RecipeScreen({super.key, required this.meal, this.fromPlan = false});

  static String _difficultyLabel(String d) {
    final x = d.toLowerCase();
    if (x.contains('facile')) return 'Très facile';
    if (x.contains('inter')) return 'Intermédiaire';
    return d;
  }

  static String _minLabel(int min) => min > 0 ? '$min min' : '—';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);
    final currentId = normalizeRecipeId(meal.id);
    final liveMeal =
        meals.where((m) => normalizeRecipeId(m.id) == currentId).firstOrNull;
    final effectiveMeal = liveMeal ?? meal;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final ink = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white70 : AppTokens.muted;
    final surface = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final hair = isDark ? Colors.white24 : AppTokens.hairline;
    final recipeBottomSafeSpace = MediaQuery.of(context).viewPadding.bottom + 92;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        extendBody: true,
        bottomNavigationBar: const SafeArea(
          top: false,
          child: BottomNav(popRouteFirst: true),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barre corail : commence sous la barre de statut / encoche (pas sous l’heure / batterie).
            SafeArea(
              bottom: false,
              child: Container(
                color: AppTokens.coral,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        effectiveMeal.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fraunces(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusLg),
                        child: Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            SizedBox(
                              height: 300,
                              width: double.infinity,
                              child: MealImage(
                                photo: effectiveMeal.photo,
                                fallbackKey: effectiveMeal.title,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                width: 54,
                                height: 54,
                                alignment: Alignment.center,
                                child: Material(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => ref
                                        .read(mealsProvider.notifier)
                                        .toggleFavorite(effectiveMeal.id),
                                    child: SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Icon(
                                        effectiveMeal.isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 22,
                                        color: AppTokens.coral,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Tag(label: meal.typeLabel),
                              const SizedBox(width: 8),
                              _Tag(label: _difficultyLabel(meal.difficulty)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Métadonnées (pas d’avis / pas de notes)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.schedule_outlined,
                                    size: 16, color: muted),
                                const SizedBox(width: 6),
                                Text(meal.time,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: ink)),
                                Text(' · ',
                                    style: TextStyle(
                                        color: muted, fontSize: 13)),
                                Icon(Icons.restaurant_menu_outlined,
                                    size: 16, color: muted),
                                const SizedBox(width: 6),
                                Text(_difficultyLabel(meal.difficulty),
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: ink)),
                                Text(' · ',
                                    style: TextStyle(
                                        color: muted, fontSize: 13)),
                                Icon(Icons.savings_outlined,
                                    size: 16, color: muted),
                                const SizedBox(width: 6),
                                Text('Bon marché',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: ink)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          Text(
                            'Ingrédients',
                            style: GoogleFonts.fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final ing = meal.ingredients[i];
                          return _IngredientEmojiTile(
                            ingredient: ing,
                            surface: surface,
                            hair: hair,
                            ink: ink,
                            muted: muted,
                          );
                        },
                        childCount: meal.ingredients.length,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
                      child: Text(
                        'Préparation',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.coral,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFF3F0EA),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusMd),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Temps total : ${meal.time}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            Divider(height: 24, color: hair),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Préparation',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: ink)),
                                      const SizedBox(height: 4),
                                      Text(_minLabel(meal.prepTimeMin),
                                          style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: muted)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Repos',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: ink)),
                                      const SizedBox(height: 4),
                                      Text(_minLabel(meal.restTimeMin),
                                          style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: muted)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text('Cuisson',
                                          style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: ink)),
                                      const SizedBox(height: 4),
                                      Text(_minLabel(meal.cookTimeMin),
                                          style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: muted)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (meal.steps.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF3F0EA),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusMd),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Étapes',
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...List.generate(meal.steps.length, (i) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: i == meal.steps.length - 1 ? 0 : 10,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${i + 1}. ',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTokens.coral,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          meal.steps[i],
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            height: 1.5,
                                            color: ink,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (meal.steps.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 52, 18, 24),
                        child: _CommencerRecetteButton(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _CookingScreen(meal: meal, fromPlan: fromPlan),
                            ),
                          ),
                        ),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: recipeBottomSafeSpace),
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

class _CommencerRecetteButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CommencerRecetteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.coral,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTokens.coralDeep, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🧑‍🍳', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'Commencer la recette',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientEmojiTile extends StatelessWidget {
  final Ingredient ingredient;
  final Color surface;
  final Color hair;
  final Color ink;
  final Color muted;

  const _IngredientEmojiTile({
    required this.ingredient,
    required this.surface,
    required this.hair,
    required this.ink,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hair),
            ),
            alignment: Alignment.center,
            child: buildIngredientIcon(ingredient.name, emojiSize: 36),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          ingredient.qty,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: muted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          ingredient.name,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Mode cuisine : étape par étape ─────────────────────────────────────────

class _CookingScreen extends ConsumerStatefulWidget {
  final Meal meal;
  final bool fromPlan;
  const _CookingScreen({required this.meal, this.fromPlan = false});

  @override
  ConsumerState<_CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends ConsumerState<_CookingScreen> {
  int _current = 0;
  bool _showIntro = true;
  final _tts = ElevenLabsTtsService();
  final _player = AudioPlayer();
  bool _isSpeaking = false;

  Ingredient? _ingredientForStep(int stepIndex) {
    final list = widget.meal.ingredients;
    if (list.isEmpty) return null;
    final i = stepIndex.clamp(0, list.length - 1);
    return list[i];
  }

  void _next() {
    if (_showIntro) {
      setState(() => _showIntro = false);
      _speakCurrentStep();
      return;
    }
    final total = widget.meal.steps.length;
    if (_current < total - 1) {
      setState(() => _current++);
      _speakCurrentStep();
    } else {
      _finishAndPop();
    }
  }

  Future<void> _finishAndPop() async {
    final meal = widget.meal;

    // Retire les ingrédients utilisés du frigo
    final usedNames = meal.ingredients
        .map((i) => i.name.toLowerCase().trim())
        .toSet();
    final fridge = List<String>.from(ref.read(detectedIngredientsProvider));
    final updatedFridge = fridge
        .where((item) => !usedNames.contains(item.toLowerCase().trim()))
        .toList();
    ref.read(detectedIngredientsProvider.notifier).state = updatedFridge;
    await persistFridgeToNeon(updatedFridge);

    // Retire la recette si elle n'est pas en favoris (pas depuis le planning)
    if (!widget.fromPlan) {
      final liveMeal = ref
          .read(mealsProvider)
          .where((m) => normalizeRecipeId(m.id) == normalizeRecipeId(meal.id))
          .firstOrNull;
      final isFavorite = liveMeal?.isFavorite ?? meal.isFavorite;
      if (!isFavorite) {
        await ref.read(mealsProvider.notifier).removeMeal(meal.id);
      }
    }

    if (mounted) Navigator.pop(context);
  }

  void _prev() {
    if (_current > 0) {
      setState(() => _current--);
      _speakCurrentStep();
    }
  }

  Future<void> _speakCurrentStep() async {
    if (_isSpeaking) return;
    final steps = widget.meal.steps;
    if (steps.isEmpty || _current >= steps.length) return;

    try {
      setState(() => _isSpeaking = true);
      await _player.stop();
      final audioBytes = await _tts.synthesize(steps[_current]);
      final dataUrl = 'data:audio/mpeg;base64,${base64Encode(audioBytes)}';
      await _player.play(UrlSource(dataUrl), volume: 1.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio indisponible: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.meal.steps;
    final total = steps.length;
    if (total == 0) {
      return Scaffold(
        body: Center(
          child: Text('Aucune étape',
              style: GoogleFonts.inter(color: AppTokens.muted)),
        ),
      );
    }

    final isLast = _current == total - 1;
    final isFirst = _current == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final ink = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white60 : AppTokens.muted;
    final hair = isDark ? Colors.white24 : AppTokens.hairlineSoft;
    final surface = isDark ? const Color(0xFF2A2A2A) : AppTokens.surface;
    final ing = _ingredientForStep(_current);

    if (_showIntro) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: ink, size: 24),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ingrédients nécessaires',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fraunces(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                        border: Border.all(color: hair),
                      ),
                      child: ListView.separated(
                        itemCount: widget.meal.ingredients.length,
                        separatorBuilder: (_, __) => Divider(color: hair, height: 14),
                        itemBuilder: (_, i) {
                          final ingredient = widget.meal.ingredients[i];
                          return Row(
                            children: [
                              SizedBox(
                                width: 26,
                                height: 26,
                                child: Center(
                                  child: buildIngredientIcon(
                                    ingredient.name,
                                    emojiSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ingredient.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ink,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ingredient.qty,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: AppTokens.coral,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: _next,
                      borderRadius: BorderRadius.circular(999),
                      splashColor: Colors.white24,
                      highlightColor: Colors.white10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTokens.coralDeep, width: 1.5),
                        ),
                        child: Text(
                          'Démarrer la recette',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<int>(_current),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(
                      begin: _current / total,
                      end: (_current + 1) / total,
                    ),
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value.clamp(0.001, 1.0),
                      minHeight: 5,
                      backgroundColor: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFE8E4DC),
                      color: AppTokens.coral,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 4, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'ÉTAPE ${_current + 1}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppTokens.coral,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: ink, size: 24),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_current),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ing != null) ...[
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radiusMd),
                                border: Border.all(color: hair),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ing.photo.isNotEmpty
                                  ? MealImage(
                                      photo: ing.photo,
                                      fit: BoxFit.cover,
                                    )
                                  : Center(
                                      child: buildIngredientIcon(
                                        ing.name,
                                        emojiSize: 34,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ing.qty,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Divider(height: 1, thickness: 1, color: hair),
                            const SizedBox(height: 20),
                          ],
                          Text(
                            steps[_current],
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: ink,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Tooltip(
                              message: 'Relire cette étape',
                              child: IconButton(
                                onPressed: _isSpeaking ? null : _speakCurrentStep,
                                icon: Icon(
                                  _isSpeaking
                                      ? Icons.graphic_eq_rounded
                                      : Icons.volume_up_outlined,
                                  color: _isSpeaking
                                      ? AppTokens.coral
                                      : ink.withValues(alpha: 0.85),
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    if (!isFirst) ...[
                      GestureDetector(
                        onTap: _prev,
                        child: Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusMd),
                            border: Border.all(color: hair),
                          ),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 20, color: ink),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Material(
                        color: AppTokens.coral,
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          onTap: _next,
                          borderRadius: BorderRadius.circular(999),
                          splashColor: Colors.white24,
                          highlightColor: Colors.white10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: AppTokens.coralDeep, width: 1.5),
                            ),
                            child: Text(
                              isLast ? 'Terminer' : 'Suivant',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets helpers ────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppTokens.coralSoft,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.coral,
        ),
      ),
    );
  }
}
