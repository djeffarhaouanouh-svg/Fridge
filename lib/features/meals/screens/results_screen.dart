import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/glass_button.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';
import 'recipe_screen.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals = ref.watch(mealsProvider);
    final ingredients = ref.watch(detectedIngredientsProvider);

    return Scaffold(
      backgroundColor: AppTokens.paper,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppTokens.ink),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Voici ce qu\'on a trouvé',
                        style: GoogleFonts.fraunces(
                          fontSize: 16, fontWeight: FontWeight.w600, color: AppTokens.ink,
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
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  // Section ingrédients détectés
                  if (ingredients.isNotEmpty) ...[
                    Text(
                      'DÉTECTÉS · ${ingredients.length}',
                      style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppTokens.coral, letterSpacing: 0.06 * 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        ...ingredients.map((ing) => _IngredientTag(label: ing)),
                        GestureDetector(
                          onTap: () {},
                          child: Text('+ Ajouter',
                            style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: AppTokens.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: AppTokens.hairlineSoft),
                    const SizedBox(height: 20),
                  ],

                  // Titre section recettes
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${meals.length} recettes pour ',
                          style: GoogleFonts.fraunces(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppTokens.ink, height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'ce soir',
                          style: GoogleFonts.fraunces(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppTokens.coral, fontStyle: FontStyle.italic,
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
                      fontSize: 13, fontWeight: FontWeight.w500, color: AppTokens.muted,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Liste des recettes
                  ...List.generate(meals.length, (i) => _RecipeRow(
                    meal: meals[i],
                    index: i,
                    detectedCount: ingredients.isNotEmpty ? ingredients.length : meals[i].ingredients.length,
                  )),

                  const SizedBox(height: 28),

                  // CTA "Générer plus de recettes"
                  GlassButton(
                    label: 'Générer plus de recettes',
                    icon: Icons.auto_awesome,
                    color: GlassButtonColor.green,
                    size: GlassButtonSize.lg,
                    fullWidth: true,
                    onTap: () {},
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

class _IngredientTag extends StatelessWidget {
  final String label;
  const _IngredientTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5, height: 5,
            decoration: const BoxDecoration(
              color: AppTokens.ink, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
            style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeRow extends ConsumerWidget {
  final Meal meal;
  final int index;
  final int detectedCount;
  const _RecipeRow({required this.meal, required this.index, required this.detectedCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = meal.ingredients.length;
    final have = total;
    final num = (index + 1).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () {
        if (!meal.locked) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => RecipeScreen(meal: meal),
          ));
        }
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  child: SizedBox(
                    width: 72, height: 72,
                    child: meal.photo.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: meal.photo, fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppTokens.placeholder),
                            errorWidget: (_, __, ___) => Container(color: AppTokens.placeholder),
                          )
                        : Container(color: AppTokens.placeholder),
                  ),
                ),
                const SizedBox(width: 14),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('N°$num',
                        style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppTokens.coral, letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(meal.title,
                        style: GoogleFonts.fraunces(
                          fontSize: 15.5, fontWeight: FontWeight.w600,
                          color: AppTokens.ink, height: 1.25,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined, size: 13, color: AppTokens.muted),
                          const SizedBox(width: 4),
                          Text(meal.time,
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w500, color: AppTokens.muted,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('·',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTokens.muted),
                            ),
                          ),
                          Text('$have/$total ✓',
                            style: GoogleFonts.inter(
                              fontSize: 12, fontWeight: FontWeight.w600, color: AppTokens.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Séparateur coral
          Container(height: 1.5, color: AppTokens.coral.withOpacity(0.25)),
        ],
      ),
    );
  }
}
