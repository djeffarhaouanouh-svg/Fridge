import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/glass_button.dart';
import '../../meals/providers/meals_provider.dart';
import '../models/meal.dart';

class RecipeScreen extends ConsumerWidget {
  final Meal meal;
  const RecipeScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = meal.ingredients.length;

    return Scaffold(
      backgroundColor: AppTokens.paper,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: GlassButton(
            label: 'Commencer la recette',
            icon: Icons.play_arrow_rounded,
            color: GlassButtonColor.green,
            size: GlassButtonSize.lg,
            fullWidth: true,
            onTap: () {},
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero image
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 280,
                  child: meal.photo.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: meal.photo,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppTokens.placeholder),
                          errorWidget: (_, __, ___) => Container(color: AppTokens.placeholder),
                        )
                      : Container(color: AppTokens.placeholder),
                ),
              ),

              // Fiche recette (fond paper, coins arrondis haut)
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

                      // Section étapes
                      if (meal.steps.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Text('Préparation',
                          style: GoogleFonts.fraunces(
                            fontSize: 18, fontWeight: FontWeight.w600, color: AppTokens.ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...meal.steps.asMap().entries.map(
                          (e) => _StepRow(number: e.key + 1, text: e.value),
                        ),
                      ],

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
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_ios_new, size: 16, color: AppTokens.ink),
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
                      color: Colors.white.withOpacity(0.85),
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

class _StepRow extends StatelessWidget {
  final int number;
  final String text;
  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.coralSoft,
              shape: BoxShape.circle,
            ),
            child: Text('$number',
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppTokens.coral,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(text,
                style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w400,
                  color: AppTokens.inkSoft, height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
