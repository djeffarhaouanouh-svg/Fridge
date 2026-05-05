import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/meal_image.dart';
import '../../../core/widgets/glass_button.dart';
import '../../meals/providers/meals_provider.dart';
import '../models/meal.dart';

// ─── Fiche recette (ingrédients) ────────────────────────────────────────────

class RecipeScreen extends ConsumerWidget {
  final Meal meal;
  const RecipeScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = meal.ingredients.length;

    return Scaffold(
      backgroundColor: AppTokens.paper,
      bottomNavigationBar: meal.steps.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: GlassButton(
                  label: 'Commencer la recette',
                  icon: Icons.play_arrow_rounded,
                  color: GlassButtonColor.green,
                  size: GlassButtonSize.lg,
                  fullWidth: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _CookingScreen(meal: meal),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero image
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: MealImage(photo: meal.photo),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTokens.paper,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  transform: Matrix4.translationValues(0, -24, 0),
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tags
                      Row(
                        children: [
                          _Tag(label: meal.typeLabel),
                          const SizedBox(width: 8),
                          _Tag(label: meal.difficulty),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Titre
                      Text(
                        meal.title,
                        style: GoogleFonts.fraunces(
                          fontSize: 24, fontWeight: FontWeight.w700,
                          color: AppTokens.ink, height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Metadata
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 14, color: AppTokens.muted),
                          const SizedBox(width: 4),
                          Text(meal.time,
                            style: GoogleFonts.inter(fontSize: 13, color: AppTokens.muted, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          Icon(Icons.local_fire_department_outlined, size: 14, color: AppTokens.muted),
                          const SizedBox(width: 4),
                          Text('${meal.kcal} kcal',
                            style: GoogleFonts.inter(fontSize: 13, color: AppTokens.muted, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 12),
                          Icon(Icons.star_rounded, size: 14, color: AppTokens.coral),
                          const SizedBox(width: 4),
                          Text('4.7',
                            style: GoogleFonts.inter(fontSize: 13, color: AppTokens.muted, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Section ingrédients
                      Row(
                        children: [
                          Text('Ingrédients',
                            style: GoogleFonts.fraunces(
                              fontSize: 18, fontWeight: FontWeight.w600, color: AppTokens.ink,
                            ),
                          ),
                          const Spacer(),
                          Text('$total/$total dans ton frigo',
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.coral,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Liste ingrédients
                      ...meal.ingredients.map((ing) => _IngredientRow(ingredient: ing)),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bouton back
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppTokens.ink),
                ),
              ),
            ),
          ),

          // Bouton favori
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: GestureDetector(
                  onTap: () => ref.read(mealsProvider.notifier).toggleFavorite(meal.id),
                  child: Container(
                    width: 36, height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      meal.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18, color: AppTokens.coral,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
            // Header : fermer + titre
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

            // Dots + compteur
            Center(
              child: Column(
                children: [
                  // Dots
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

            // Contenu de l'étape
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
                      // Numéro de l'étape
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

            // Boutons navigation
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Row(
                children: [
                  // Précédent (caché sur la 1ère étape)
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

class _IngredientRow extends StatelessWidget {
  final Ingredient ingredient;
  const _IngredientRow({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTokens.coral, shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(ingredient.name,
              style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w500, color: AppTokens.ink,
              ),
            ),
          ),
          Text(ingredient.qty,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w400, color: AppTokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}
