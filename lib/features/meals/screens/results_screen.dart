import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_header.dart';
import '../../meals/providers/meals_provider.dart';
import '../../meals/models/meal.dart';
import 'recipe_screen.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen> {
  final PageController _heroController = PageController();
  int _heroPage = 0;

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealsProvider);
    final heroMeals = meals.take(1).toList();
    final fridgeMeals = meals;

    return Scaffold(
      backgroundColor: AppTokens.paper,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: AppHeader(brand: true)),

          // Titre "Qu'est-ce qu'on mange ce soir ?"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Qu\'est-ce qu\'on mange ',
                          style: GoogleFonts.fraunces(
                            fontSize: 27, fontWeight: FontWeight.w700,
                            color: AppTokens.ink, height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'ce soir',
                          style: GoogleFonts.fraunces(
                            fontSize: 27, fontWeight: FontWeight.w700,
                            color: AppTokens.coral, fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: ' ?',
                          style: GoogleFonts.fraunces(
                            fontSize: 27, fontWeight: FontWeight.w700,
                            color: AppTokens.ink, height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${meals.length} idées à partir de ton frigo',
                    style: GoogleFonts.inter(
                      fontSize: 13.5, fontWeight: FontWeight.w500,
                      color: AppTokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Hero carousel
          if (heroMeals.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(
                    height: 230,
                    child: PageView.builder(
                      controller: _heroController,
                      onPageChanged: (i) => setState(() => _heroPage = i),
                      itemCount: heroMeals.length,
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () {
                          final meal = heroMeals[i];
                          if (!meal.locked) {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => RecipeScreen(meal: meal),
                            ));
                          }
                        },
                        child: _HeroCard(meal: heroMeals[i], index: i),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(heroMeals.length, (i) {
                      final isActive = i == _heroPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: isActive ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isActive ? AppTokens.coral : AppTokens.placeholder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

          // Section "Avec ton frigo"
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 14),
              child: Text(
                'Avec ton frigo',
                style: GoogleFonts.fraunces(
                  fontSize: 19, fontWeight: FontWeight.w600, color: AppTokens.ink,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 215,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                itemCount: fridgeMeals.length,
                itemBuilder: (context, i) => _CompactCard(meal: fridgeMeals[i]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _HeroCard extends ConsumerWidget {
  final Meal meal;
  final int index;
  const _HeroCard({required this.meal, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: meal.photo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: meal.photo, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: AppTokens.placeholder),
                      errorWidget: (_, __, ___) => Container(color: AppTokens.placeholder),
                    )
                  : Container(color: AppTokens.placeholder),
            ),
            // Gradient sombre en bas
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xD9000000)],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
            ),
            // Contenu bas
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECETTE DU SOIR',
                    style: GoogleFonts.inter(
                      fontSize: 10.5, fontWeight: FontWeight.w700,
                      color: AppTokens.coral, letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    meal.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 19, fontWeight: FontWeight.w600,
                      color: Colors.white, height: 1.2,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: AppTokens.coral),
                      const SizedBox(width: 4),
                      Text(
                        '4.7 · 213 avis · ${meal.time}',
                        style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTokens.coral,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'RECETTE ${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 9.5, fontWeight: FontWeight.w700,
                            color: Colors.white, letterSpacing: 0.5,
                          ),
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
    );
  }
}

class _CompactCard extends ConsumerWidget {
  final Meal meal;
  const _CompactCard({required this.meal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = meal.ingredients.length;
    final have = total;

    return GestureDetector(
      onTap: () {
        if (!meal.locked) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => RecipeScreen(meal: meal),
          ));
        }
      },
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              child: SizedBox(
                height: 148,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: meal.photo.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: meal.photo, fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: AppTokens.placeholder),
                              errorWidget: (_, __, ___) => Container(color: AppTokens.placeholder),
                            )
                          : Container(color: AppTokens.placeholder),
                    ),
                    // Heart
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => ref.read(mealsProvider.notifier).toggleFavorite(meal.id),
                        child: Container(
                          width: 32, height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            meal.isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: AppTokens.coral,
                          ),
                        ),
                      ),
                    ),
                    // Badge ingrédients
                    if (total > 0)
                      Positioned(
                        left: 8, bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                          ),
                          child: Text(
                            '$have/$total ✓',
                            style: GoogleFonts.inter(
                              fontSize: 10.5, fontWeight: FontWeight.w700,
                              color: AppTokens.ink,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              meal.title,
              style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppTokens.ink,
              ),
              maxLines: 2, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 12, color: AppTokens.coral),
                const SizedBox(width: 3),
                Text(
                  '4.6 · ${meal.time}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5, fontWeight: FontWeight.w500, color: AppTokens.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
