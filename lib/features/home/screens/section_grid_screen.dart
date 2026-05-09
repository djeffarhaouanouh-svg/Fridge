import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/ingredient_category.dart';
import '../../../core/widgets/meal_image.dart';
import '../../meals/models/meal.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/screens/recipe_screen.dart';

/// Page plein écran qui affiche une liste de recettes en grille 2 colonnes.
class RecipesGridScreen extends ConsumerWidget {
  final String title;
  final List<Meal> meals;
  final bool isGenerated;

  const RecipesGridScreen({
    super.key,
    required this.title,
    required this.meals,
    this.isGenerated = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white60 : AppTokens.muted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.fraunces(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
      ),
      body: meals.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucune recette pour le moment',
                  style: GoogleFonts.inter(fontSize: 13.5, color: mutedColor),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
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

/// Page plein écran qui affiche les ingrédients détectés en grille 2 colonnes.
class IngredientsGridScreen extends ConsumerWidget {
  const IngredientsGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredients = ref.watch(detectedIngredientsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final mutedColor = isDark ? Colors.white60 : AppTokens.muted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: titleColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tes ingrédients',
          style: GoogleFonts.fraunces(
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
      ),
      body: ingredients.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Scanne ton frigo pour voir tes ingrédients',
                  style: GoogleFonts.inter(fontSize: 13.5, color: mutedColor),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.4,
              ),
              itemCount: ingredients.length,
              itemBuilder: (context, i) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            ),
    );
  }
}
