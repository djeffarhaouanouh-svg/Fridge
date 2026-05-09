import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/ingredient_category.dart';
import '../../../core/widgets/meal_image.dart';
import '../../meals/models/meal.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/screens/recipe_screen.dart';

/// Affiche une grille 2 colonnes de recettes en overlay (modal bottom sheet).
void showRecipesGridSheet(
  BuildContext context, {
  required String title,
  required List<Meal> meals,
  bool isGenerated = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _SectionGridSheet(
      title: title,
      builder: (controller) => _RecipesGrid(
        meals: meals,
        isGenerated: isGenerated,
        controller: controller,
      ),
    ),
  );
}

/// Affiche les ingrédients en grille 2 colonnes en overlay.
void showIngredientsGridSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _SectionGridSheet(
      title: 'Tes ingrédients',
      builder: (controller) => _IngredientsGrid(controller: controller),
    ),
  );
}

class _SectionGridSheet extends StatelessWidget {
  final String title;
  final Widget Function(ScrollController controller) builder;

  const _SectionGridSheet({
    required this.title,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white60 : AppTokens.muted;
    final sheetColor = isDark ? const Color(0xFF1B1B1B) : AppTokens.paper;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: titleColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(child: builder(scrollController)),
          ],
        ),
      ),
    );
  }
}

class _RecipesGrid extends StatelessWidget {
  final List<Meal> meals;
  final bool isGenerated;
  final ScrollController controller;

  const _RecipesGrid({
    required this.meals,
    required this.isGenerated,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white60 : AppTokens.muted;

    if (meals.isEmpty) {
      return ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Aucune recette pour le moment',
                style: GoogleFonts.inter(fontSize: 13.5, color: mutedColor),
              ),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 18,
        childAspectRatio: 0.78,
      ),
      itemCount: meals.length,
      itemBuilder: (context, i) => _GridRecipeCard(
        meal: meals[i],
        isGenerated: isGenerated,
        index: i,
      ),
    );
  }
}

class _GridRecipeCard extends ConsumerWidget {
  final Meal meal;
  final bool isGenerated;
  final int index;

  const _GridRecipeCard({
    required this.meal,
    required this.isGenerated,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rating = 4.5 + ((index % 3) * 0.1);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeScreen(
              meal: meal,
              isGeneratedRecipe: isGenerated,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MealImage(
                    photo: meal.photo,
                    fallbackKey: meal.title,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            meal.emoji.isNotEmpty
                ? '${meal.emoji} ${meal.title}'
                : meal.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppTokens.ink,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 14, color: AppTokens.coral),
              const SizedBox(width: 4),
              Text(
                '${rating.toStringAsFixed(1)} · ${meal.time}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppTokens.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IngredientsGrid extends ConsumerWidget {
  final ScrollController controller;
  const _IngredientsGrid({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredients = ref.watch(detectedIngredientsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white60 : AppTokens.muted;

    if (ingredients.isEmpty) {
      return ListView(
        controller: controller,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Scanne ton frigo pour voir tes ingrédients',
                style: GoogleFonts.inter(fontSize: 13.5, color: mutedColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          border: Border.all(color: AppTokens.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTokens.surface2,
                shape: BoxShape.circle,
              ),
              child: buildIngredientIcon(ingredients[i]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ingredients[i],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTokens.ink,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
