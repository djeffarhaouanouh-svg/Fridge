import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_tokens.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';
import 'recipe_screen.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);
    final scanStatus = ref.watch(scanStatusProvider);
    final ingredients = ref.watch(detectedIngredientsProvider);
    final isLoading = scanStatus == ScanStatus.loading;

    return Scaffold(
      backgroundColor: AppTokens.bg,
      body: isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTokens.accent),
                  const SizedBox(height: 16),
                  Text(
                    'Analyse en cours…',
                    style: GoogleFonts.dmSans(color: AppTokens.muted),
                  ),
                ],
              ),
            )
          : SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tes recettes',
                      style: GoogleFonts.syne(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${meals.length} résultats trouvés',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: AppTokens.muted,
                      ),
                    ),
                    if (ingredients.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ingredients
                            .map((ing) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTokens.accentDim,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTokens.accent.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    ing,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppTokens.accent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Meals grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final meal = meals[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _MealCard(meal: meal),
                    );
                  },
                  childCount: meals.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends ConsumerWidget {
  final Meal meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (!meal.locked) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeScreen(meal: meal),
            ),
          );
        }
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          border: Border.all(color: AppTokens.border),
        ),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                child: CachedNetworkImage(
                  imageUrl: meal.photo,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTokens.surface,
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),

            // Locked overlay
            if (meal.locked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                    color: Colors.black.withOpacity(0.7),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 40,
                          color: AppTokens.warm,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Premium',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.warm,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Content
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Row(
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.card.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTokens.border),
                    ),
                    child: Row(
                      children: [
                        Text(
                          meal.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          meal.typeLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTokens.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Favorite button
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(mealsProvider.notifier)
                          .toggleFavorite(meal.id);
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTokens.card.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTokens.border),
                      ),
                      child: Icon(
                        meal.isFavorite ? Icons.star : Icons.star_border,
                        size: 16,
                        color:
                            meal.isFavorite ? AppTokens.warm : AppTokens.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom info
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.title,
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.local_fire_department_outlined,
                        label: '${meal.kcal} kcal',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: meal.time,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.whatshot_outlined,
                        label: meal.difficulty,
                      ),
                    ],
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTokens.card.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppTokens.muted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}
