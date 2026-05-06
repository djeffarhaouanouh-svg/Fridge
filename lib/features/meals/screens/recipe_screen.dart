import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/ingredient_category.dart';
import '../../../core/widgets/meal_image.dart';
import '../../../core/widgets/glass_button.dart';
import '../../meals/providers/meals_provider.dart';
import '../../navigation/widgets/bottom_nav.dart';
import '../models/meal.dart';

// ─── Fiche recette ─────────────────────────────────────────────────────────

class RecipeScreen extends ConsumerWidget {
  final Meal meal;
  const RecipeScreen({super.key, required this.meal});

  static String _difficultyLabel(String d) {
    final x = d.toLowerCase();
    if (x.contains('facile')) return 'Très facile';
    if (x.contains('inter')) return 'Intermédiaire';
    return d;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final ink = isDark ? Colors.white : AppTokens.ink;
    final muted = isDark ? Colors.white70 : AppTokens.muted;
    final surface = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final hair = isDark ? Colors.white24 : AppTokens.hairline;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
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
                        meal.title,
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
                              child: MealImage(photo: meal.photo),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => ref
                                    .read(mealsProvider.notifier)
                                    .toggleFavorite(meal.id),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    meal.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 22,
                                    color: AppTokens.coral,
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
                      padding: const EdgeInsets.fromLTRB(18, 44, 18, 20),
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
                                      Text('—',
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
                                      Text('—',
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
                                      Text(meal.time,
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
                        padding: const EdgeInsets.fromLTRB(18, 28, 18, 36),
                        child: _CommencerRecetteButton(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _CookingScreen(meal: meal),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTokens.coral, width: 1.5),
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
                  color: AppTokens.coral,
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

class _CookingScreen extends StatefulWidget {
  final Meal meal;
  const _CookingScreen({required this.meal});

  @override
  State<_CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends State<_CookingScreen> {
  int _current = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    final total = widget.meal.steps.length;
    if (_current < total - 1) {
      _pageController.animateToPage(
        _current + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_current > 0) {
      _pageController.animateToPage(
        _current - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.meal.steps;
    final total = steps.length;
    final isLast = _current == total - 1;
    final isFirst = _current == 0;

    return Scaffold(
      backgroundColor: AppTokens.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppTokens.ink, size: 22),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(widget.meal.title,
                        style: GoogleFonts.fraunces(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppTokens.ink,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(total, (i) {
                      final isActive = i == _current;
                      final isDone = i < _current;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppTokens.coral.withValues(alpha: 0.4)
                              : isActive
                                  ? AppTokens.coral
                                  : AppTokens.hairline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Étape ${_current + 1} sur $total',
                    style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.muted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: total,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52, height: 52,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppTokens.coralSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                          style: GoogleFonts.fraunces(
                            fontSize: 22, fontWeight: FontWeight.w700, color: AppTokens.coral,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(steps[i],
                        style: GoogleFonts.inter(
                          fontSize: 19, fontWeight: FontWeight.w400,
                          color: AppTokens.ink, height: 1.65,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Row(
                children: [
                  AnimatedOpacity(
                    opacity: isFirst ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: isFirst ? null : _prev,
                      child: Container(
                        width: 50, height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTokens.surface,
                          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                          border: Border.all(color: AppTokens.hairline),
                        ),
                        child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTokens.ink),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      label: isLast ? 'Terminer' : 'Suivant',
                      icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      color: GlassButtonColor.green,
                      size: GlassButtonSize.lg,
                      fullWidth: true,
                      onTap: _next,
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
