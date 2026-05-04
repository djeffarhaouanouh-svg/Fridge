import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/ingredient_category.dart';
import '../../../core/widgets/app_header.dart';
import '../../meals/providers/meals_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../meals/models/meal.dart';
import '../../meals/screens/recipe_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    final detectedIngredients = ref.watch(detectedIngredientsProvider);
    final heroMeals = meals.take(3).toList();
    final firstName = ref.watch(userProfileProvider).name.split(' ').first;

    return Scaffold(
      backgroundColor: AppTokens.paper,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: AppHeader(brand: true)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Bonjour ',
                          style: GoogleFonts.fraunces(
                            fontSize: 19,
                            fontWeight: FontWeight.w400,
                            color: AppTokens.inkSoft,
                          ),
                        ),
                        TextSpan(
                          text: firstName,
                          style: GoogleFonts.fraunces(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.coral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Qu\'est-ce qu\'on mange ',
                          style: GoogleFonts.fraunces(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'ce soir',
                          style: GoogleFonts.fraunces(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.coral,
                            fontStyle: FontStyle.italic,
                            height: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: ' ?',
                          style: GoogleFonts.fraunces(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.ink,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meals.length} idées à partir de ton frigo',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),

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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeScreen(meal: meal),
                              ),
                            );
                          }
                        },
                        child: _HeroCard(meal: heroMeals[i], index: i),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
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
                          color: isActive
                              ? AppTokens.coral
                              : AppTokens.placeholder,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 36, 18, 14),
              child: Text(
                'Recettes populaires',
                style: GoogleFonts.fraunces(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink,
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
                itemCount: meals.length,
                itemBuilder: (context, i) => _CompactCard(meal: meals[i]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 36, 18, 14),
              child: Text(
                'Tes ingrédients',
                style: GoogleFonts.fraunces(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.ink,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: detectedIngredients.isEmpty
                ? _IngredientsEmptyState()
                : SizedBox(
                    height: 88,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      itemCount: detectedIngredients.length,
                      itemBuilder: (context, i) =>
                          _IngredientPill(name: detectedIngredients[i]),
                    ),
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 110)),
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
            Positioned.fill(
              child: meal.photo.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: meal.photo,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppTokens.placeholder),
                      errorWidget: (_, __, ___) =>
                          Container(color: AppTokens.placeholder),
                    )
                  : Container(color: AppTokens.placeholder),
            ),
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
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECETTE DU SOIR',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.coral,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    meal.title,
                    style: GoogleFonts.fraunces(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: AppTokens.coral),
                      const SizedBox(width: 4),
                      Text(
                        '4.7 · 213 avis · ${meal.time}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTokens.coral,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'RECETTE ${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
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
    return GestureDetector(
      onTap: () {
        if (!meal.locked) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecipeScreen(meal: meal)),
          );
        }
      },
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              child: SizedBox(
                height: 148,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: meal.photo.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: meal.photo,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: AppTokens.placeholder),
                              errorWidget: (_, __, ___) =>
                                  Container(color: AppTokens.placeholder),
                            )
                          : Container(color: AppTokens.placeholder),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(mealsProvider.notifier)
                            .toggleFavorite(meal.id),
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            meal.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: AppTokens.coral,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTokens.ink,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 12, color: AppTokens.coral),
                const SizedBox(width: 3),
                Text(
                  '4.6 · ${meal.time}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.muted,
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

class _IngredientPill extends StatelessWidget {
  final String name;
  const _IngredientPill({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.hairline, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTokens.surface2,
              shape: BoxShape.circle,
            ),
            child: buildIngredientIcon(name),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTokens.ink,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _IngredientsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: AppTokens.hairline, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 18, color: AppTokens.muted),
          const SizedBox(width: 8),
          Text(
            'Scanne ton frigo pour voir tes ingrédients',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTokens.muted,
            ),
          ),
        ],
      ),
    );
  }
}
