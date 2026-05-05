import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/fridge_sync.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/ingredient_category.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/meal_image.dart';
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
                    meals.isEmpty
                        ? 'Scanne ton frigo ou ajoute des recettes en favoris pour les voir ici'
                        : '${meals.length} recette${meals.length > 1 ? 's' : ''} dans ton app',
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
            child: meals.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: Text(
                      'Aucune recette enregistrée pour l’instant.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppTokens.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : SizedBox(
                    height: 215,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      itemCount: meals.length,
                      itemBuilder: (context, i) =>
                          _CompactCard(meal: meals[i]),
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
                          _IngredientPill(name: detectedIngredients[i], index: i),
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
            Positioned.fill(child: MealImage(photo: meal.photo)),
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
                    meal.emoji.isNotEmpty
                        ? '${meal.emoji} ${meal.title}'
                        : meal.title,
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
                    Positioned.fill(child: MealImage(photo: meal.photo)),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
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
              meal.emoji.isNotEmpty
                  ? '${meal.emoji} ${meal.title}'
                  : meal.title,
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

class _IngredientPill extends ConsumerWidget {
  final String name;
  final int index;
  const _IngredientPill({required this.name, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _IngredientEditSheet(name: name, index: index),
      ),
      child: Container(
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
      ),
    );
  }
}

class _IngredientEditSheet extends ConsumerStatefulWidget {
  final String name;
  final int index;
  const _IngredientEditSheet({required this.name, required this.index});

  @override
  ConsumerState<_IngredientEditSheet> createState() => _IngredientEditSheetState();
}

class _IngredientEditSheetState extends ConsumerState<_IngredientEditSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final val = _ctrl.text.trim();
    if (val.isEmpty) return;
    final list = List<String>.from(ref.read(detectedIngredientsProvider));
    list[widget.index] = val.toLowerCase();
    ref.read(detectedIngredientsProvider.notifier).state = list;
    await persistFridgeToNeon(list);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final list = List<String>.from(ref.read(detectedIngredientsProvider));
    list.removeAt(widget.index);
    ref.read(detectedIngredientsProvider.notifier).state = list;
    await persistFridgeToNeon(list);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _ctrl.text.isEmpty ? widget.name : _ctrl.text;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTokens.paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.muted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Emoji preview + nom
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTokens.surface2,
                    shape: BoxShape.circle,
                  ),
                  child: buildIngredientIcon(previewName),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modifier l\'ingrédient',
                        style: GoogleFonts.fraunces(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTokens.ink,
                        ),
                      ),
                      Text(
                        'L\'icône se met à jour automatiquement',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTokens.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Champ texte
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 15, color: AppTokens.ink),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Nom de l\'ingrédient',
                hintStyle: GoogleFonts.inter(color: AppTokens.muted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  borderSide: const BorderSide(color: AppTokens.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  borderSide: const BorderSide(color: AppTokens.coral, width: 1.5),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _delete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppTokens.coral.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                        border: Border.all(color: AppTokens.coral.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          'Supprimer',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.coral,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: AppTokens.ink,
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                      child: Center(
                        child: Text(
                          'Sauvegarder',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
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
