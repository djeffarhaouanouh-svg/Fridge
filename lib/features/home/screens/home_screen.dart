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
import '../providers/daily_hero_provider.dart';
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
    final heroAsync = ref.watch(dailyHeroRecipesProvider);
    final marmitonBudgetAsync = ref.watch(marmitonBudgetRecipesProvider);
    final sportAsync = ref.watch(sportRecipesProvider);
    final minceurAsync = ref.watch(minceurRecipesProvider);
    final heroMeals = heroAsync.maybeWhen(
      data: (list) => list.isNotEmpty ? list : _mockPopularMeals.take(3).toList(),
      orElse: () => _mockPopularMeals.take(3).toList(),
    );
    final budgetCards = marmitonBudgetAsync.maybeWhen(
      data: (list) {
        if (list.isEmpty) return _mockHomeSections[0].cards;
        return list
            .asMap()
            .entries
            .map(
              (entry) => _HomeCollectionCardData(
                title: entry.value.title,
                imageUrl: entry.value.photo,
                rating: 4.5 + ((entry.key % 3) * 0.1),
                meal: entry.value,
              ),
            )
            .toList();
      },
      orElse: () => _mockHomeSections[0].cards,
    );
    final sportCards = sportAsync.when(
      data: (list) {
        if (list.isEmpty) return _mockHomeSections[1].cards;
        return list
            .asMap()
            .entries
            .map(
              (entry) => _HomeCollectionCardData(
                title: entry.value.title,
                imageUrl: entry.value.photo,
                rating: 4.5 + ((entry.key % 3) * 0.1),
                meal: entry.value,
              ),
            )
            .toList();
      },
      loading: () => _mockHomeSections[1].cards,
      error: (_, __) => _mockHomeSections[1].cards,
    );
    final minceurCards = minceurAsync.when(
      data: (list) {
        if (list.isEmpty) return _mockHomeSections[1].cards;
        return list
            .asMap()
            .entries
            .map(
              (entry) => _HomeCollectionCardData(
                title: entry.value.title,
                imageUrl: entry.value.photo,
                rating: 4.5 + ((entry.key % 3) * 0.1),
                meal: entry.value,
              ),
            )
            .toList();
      },
      loading: () => _mockHomeSections[1].cards,
      error: (_, __) => _mockHomeSections[1].cards,
    );
    final firstName = ref.watch(userProfileProvider).name.split(' ').first;
    final themePreference = ref.watch(themePreferenceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : AppTokens.ink;
    final softTitleColor = isDark ? Colors.white70 : AppTokens.inkSoft;
    final mutedColor = isDark ? Colors.white60 : AppTokens.muted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              brand: true,
              trailing: SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                  tooltip: 'Basculer le thème',
                  onPressed: () {
                    final next = themePreference == ThemePreference.dark
                        ? ThemePreference.light
                        : ThemePreference.dark;
                    ref.read(themePreferenceProvider.notifier).state = next;
                  },
                  icon: Icon(
                    themePreference == ThemePreference.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: Colors.amber.shade400,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
              child: Stack(
                children: [
                  Column(
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
                                  color: softTitleColor,
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
                              text: 'On mange quoi ',
                              style: GoogleFonts.fraunces(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                  color: titleColor,
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: 'ce soir',
                              style: GoogleFonts.fraunces(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.coral,
                                fontStyle: FontStyle.italic,
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: ' ?',
                              style: GoogleFonts.fraunces(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                  color: titleColor,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detectedIngredients.isEmpty
                            ? 'Scanne ton frigo ou ajoute des recettes en favoris pour les voir ici'
                            : 'Voici 3 recettes pour toi',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (heroMeals.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (heroAsync.isLoading)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppTokens.coral,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Génération de tes recettes du soir…',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppTokens.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Stack(
                    children: [
                      SizedBox(
                        height: 280,
                        child: PageView.builder(
                          controller: _heroController,
                          onPageChanged: (i) => setState(() => _heroPage = i),
                          itemCount: heroMeals.length,
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () {
                              final meal = heroMeals[i];
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipeScreen(meal: meal),
                                ),
                              );
                            },
                            child: _HeroCard(meal: heroMeals[i], index: i),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 28,
                        child: GestureDetector(
                          onTap: heroAsync.isLoading
                              ? null
                              : () => ref
                                  .read(dailyHeroRecipesProvider.notifier)
                                  .forceRefresh(),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: heroAsync.isLoading
                                ? Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                          ),
                        ),
                      ),
                    ],
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
                'Depuis ton dernier scan',
                style: GoogleFonts.fraunces(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 215,
              child: ListView.builder(
                primary: false,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                itemCount: meals.isEmpty
                    ? _mockPopularMeals.length
                    : meals.length,
                itemBuilder: (context, i) => _CompactCard(
                  meal: meals.isEmpty ? _mockPopularMeals[i] : meals[i],
                ),
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
                  color: titleColor,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: detectedIngredients.isEmpty
                ? const _IngredientsEmptyState()
                : SizedBox(
                    height: 88,
                    child: ListView.builder(
                      primary: false,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      itemCount: detectedIngredients.length,
                      itemBuilder: (context, i) =>
                          _IngredientPill(
                            name: detectedIngredients[i],
                            index: i,
                          ),
                    ),
                  ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 50, 18, 12),
              child: Text(
                _mockHomeSections[0].title,
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                height: 248,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: budgetCards.length,
                  itemBuilder: (context, i) => _LargeCollectionCard(
                    data: budgetCards[i],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
              child: Text(
                'Prise de masse',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                height: 248,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: sportCards.length,
                  itemBuilder: (context, i) => _LargeCollectionCard(
                    data: sportCards[i],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 12),
              child: Text(
                'Minceur',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                height: 248,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: minceurCards.length,
                  itemBuilder: (context, i) => _LargeCollectionCard(
                    data: minceurCards[i],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 62)),
        ],
      ),
    );
  }
}

final List<Meal> _mockPopularMeals = [
  Meal(
    id: 'mock_1',
    type: 'balanced',
    typeLabel: 'Équilibré',
    emoji: '🥑',
    title: 'Avocat farci à la tomate et mâche',
    kcal: 320,
    protein: 'moyen',
    difficulty: 'facile',
    time: '15 min',
    locked: false,
    photo: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
    ingredients: [],
    steps: [],
    color: '#82D28C',
    isFavorite: true,
  ),
  Meal(
    id: 'mock_2',
    type: 'simple',
    typeLabel: 'Simple',
    emoji: '🍝',
    title: 'Spaghetti carbonara maison',
    kcal: 520,
    protein: 'élevé',
    difficulty: 'intermédiaire',
    time: '25 min',
    locked: false,
    photo: 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400',
    ingredients: [],
    steps: [],
    color: '#F2C94C',
  ),
  Meal(
    id: 'mock_3',
    type: 'stylish',
    typeLabel: 'Stylé',
    emoji: '🥗',
    title: 'Salade niçoise légère',
    kcal: 280,
    protein: 'moyen',
    difficulty: 'facile',
    time: '20 min',
    locked: false,
    photo: 'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?w=400',
    ingredients: [],
    steps: [],
    color: '#6FCF97',
  ),
  Meal(
    id: 'mock_4',
    type: 'balanced',
    typeLabel: 'Équilibré',
    emoji: '🍗',
    title: 'Poulet rôti aux herbes de Provence',
    kcal: 450,
    protein: 'élevé',
    difficulty: 'facile',
    time: '45 min',
    locked: false,
    photo: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c3?w=400',
    ingredients: [],
    steps: [],
    color: '#F2994A',
  ),
  Meal(
    id: 'mock_5',
    type: 'simple',
    typeLabel: 'Simple',
    emoji: '🍲',
    title: 'Soupe de lentilles corail au curry',
    kcal: 360,
    protein: 'élevé',
    difficulty: 'facile',
    time: '30 min',
    locked: false,
    photo: 'https://images.unsplash.com/photo-1547592180-85f173990554?w=400',
    ingredients: [],
    steps: [],
    color: '#EB5757',
  ),
];

final List<_HomeCollectionSection> _mockHomeSections = [
  _HomeCollectionSection(
    title: 'Étudiant fauché',
    cards: [
      _HomeCollectionCardData(
        title: 'Pâtes bolognaise budget',
        imageUrl: 'assets/images/spaghetti-bolognese.png',
        rating: 4.7,
        meal: Meal(
          id: 'home_budget_1',
          type: 'simple',
          typeLabel: 'Simple',
          emoji: '🍝',
          title: 'Pâtes bolognaise budget',
          kcal: 560,
          protein: 'moyen',
          difficulty: 'facile',
          time: '18 min',
          locked: false,
          photo: 'assets/images/spaghetti-bolognese.png',
          color: '#F2994A',
          ingredients: [
            Ingredient(name: 'Pâtes', qty: '120 g', photo: ''),
            Ingredient(name: 'Boeuf haché', qty: '150 g', photo: ''),
            Ingredient(name: 'Sauce tomate', qty: '200 ml', photo: ''),
          ],
          steps: [
            'Fais cuire les pâtes dans une eau salée.',
            'Poêle chaude: saisis le boeuf puis ajoute la sauce tomate.',
            'Mélange avec les pâtes et sers bien chaud.',
          ],
          prepTimeMin: 6,
          cookTimeMin: 12,
        ),
      ),
      _HomeCollectionCardData(
        title: 'Ramen minute',
        imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=900',
        rating: 4.6,
        meal: Meal(
          id: 'home_budget_2',
          type: 'simple',
          typeLabel: 'Simple',
          emoji: '🍜',
          title: 'Ramen minute',
          kcal: 490,
          protein: 'moyen',
          difficulty: 'facile',
          time: '16 min',
          locked: false,
          photo: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=900',
          ingredients: [
            Ingredient(name: 'Nouilles', qty: '1 paquet', photo: ''),
            Ingredient(name: 'Oeuf', qty: '1', photo: ''),
            Ingredient(name: 'Bouillon', qty: '350 ml', photo: ''),
          ],
          steps: [
            'Porte le bouillon a frémissement.',
            'Ajoute les nouilles et cuis 3 à 4 minutes.',
            'Termine avec l oeuf mollet et un peu de ciboulette.',
          ],
          color: '#F2C94C',
          prepTimeMin: 4,
          cookTimeMin: 12,
        ),
      ),
      _HomeCollectionCardData(
        title: 'Riz sauté économique',
        imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=900',
        rating: 4.5,
        meal: Meal(
          id: 'home_budget_3',
          type: 'balanced',
          typeLabel: 'Équilibré',
          emoji: '🍚',
          title: 'Riz sauté économique',
          kcal: 430,
          protein: 'moyen',
          difficulty: 'facile',
          time: '20 min',
          locked: false,
          photo: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=900',
          ingredients: [
            Ingredient(name: 'Riz cuit', qty: '180 g', photo: ''),
            Ingredient(name: 'Carotte', qty: '1', photo: ''),
            Ingredient(name: 'Oeuf', qty: '1', photo: ''),
          ],
          steps: [
            'Fais revenir les légumes en petits dés.',
            'Ajoute le riz, puis saisis à feu vif 3 minutes.',
            'Pousse le riz sur le côté et brouille l oeuf avant de mélanger.',
          ],
          color: '#6FCF97',
          prepTimeMin: 7,
          cookTimeMin: 13,
        ),
      ),
    ],
  ),
  _HomeCollectionSection(
    title: 'Salades',
    cards: [
      _HomeCollectionCardData(
        title: 'César légère',
        imageUrl: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=900',
        rating: 4.8,
        meal: Meal(
          id: 'home_salad_1',
          type: 'balanced',
          typeLabel: 'Équilibré',
          emoji: '🥗',
          title: 'César légère',
          kcal: 340,
          protein: 'moyen',
          difficulty: 'facile',
          time: '14 min',
          locked: false,
          photo: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=900',
          ingredients: [
            Ingredient(name: 'Laitue', qty: '1/2', photo: ''),
            Ingredient(name: 'Poulet', qty: '120 g', photo: ''),
            Ingredient(name: 'Parmesan', qty: '20 g', photo: ''),
          ],
          steps: [
            'Coupe la laitue et prépare les copeaux de parmesan.',
            'Poêle le poulet assaisonné puis tranche-le.',
            'Mélange avec la sauce césar et les croûtons.',
          ],
          color: '#82D28C',
          prepTimeMin: 8,
          cookTimeMin: 6,
        ),
      ),
      _HomeCollectionCardData(
        title: 'Bowl avocat-feta',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=900',
        rating: 4.7,
        meal: Meal(
          id: 'home_salad_2',
          type: 'stylish',
          typeLabel: 'Stylé',
          emoji: '🥑',
          title: 'Bowl avocat-feta',
          kcal: 360,
          protein: 'moyen',
          difficulty: 'facile',
          time: '12 min',
          locked: false,
          photo: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=900',
          ingredients: [
            Ingredient(name: 'Avocat', qty: '1', photo: ''),
            Ingredient(name: 'Feta', qty: '60 g', photo: ''),
            Ingredient(name: 'Concombre', qty: '1/2', photo: ''),
          ],
          steps: [
            'Coupe tous les ingrédients en cubes.',
            'Ajoute un filet d huile d olive et du citron.',
            'Assaisonne puis mélange délicatement.',
          ],
          color: '#6FCF97',
          prepTimeMin: 10,
          cookTimeMin: 2,
        ),
      ),
      _HomeCollectionCardData(
        title: 'Salade de quinoa',
        imageUrl: 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=900',
        rating: 4.6,
        meal: Meal(
          id: 'home_salad_3',
          type: 'balanced',
          typeLabel: 'Équilibré',
          emoji: '🥗',
          title: 'Salade de quinoa',
          kcal: 320,
          protein: 'moyen',
          difficulty: 'facile',
          time: '15 min',
          locked: false,
          photo: 'https://images.unsplash.com/photo-1505576399279-565b52d4ac71?w=900',
          ingredients: [
            Ingredient(name: 'Quinoa', qty: '80 g', photo: ''),
            Ingredient(name: 'Tomates cerises', qty: '8', photo: ''),
            Ingredient(name: 'Menthe', qty: '6 feuilles', photo: ''),
          ],
          steps: [
            'Rince puis cuis le quinoa dans deux volumes d eau.',
            'Laisse tiédir et ajoute tomates et herbes.',
            'Assaisonne avec citron, huile d olive et sel.',
          ],
          color: '#27AE60',
          prepTimeMin: 9,
          cookTimeMin: 6,
        ),
      ),
    ],
  ),
];

class _HomeCollectionSection {
  final String title;
  final List<_HomeCollectionCardData> cards;

  const _HomeCollectionSection({
    required this.title,
    required this.cards,
  });
}

class _HomeCollectionCardData {
  final String title;
  final String imageUrl;
  final double rating;
  final Meal meal;

  const _HomeCollectionCardData({
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.meal,
  });
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
              child: MealImage(
                photo: meal.photo,
                fallbackKey: meal.title,
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeScreen(meal: meal)),
        );
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
                      child: MealImage(
                        photo: meal.photo,
                        fallbackKey: meal.title,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => ref
                                .read(mealsProvider.notifier)
                                .toggleFavorite(meal.id),
                            child: SizedBox(
                              width: 30,
                              height: 30,
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
                color: isDark ? Colors.white : AppTokens.ink,
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
                    color: isDark ? Colors.white70 : AppTokens.muted,
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

class _LargeCollectionCard extends ConsumerWidget {
  final _HomeCollectionCardData data;
  const _LargeCollectionCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeScreen(meal: data.meal)),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
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
                      photo: data.imageUrl,
                      fallbackKey: data.title,
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
              data.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTokens.ink,
                height: 1.15,
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
                  '${data.rating.toStringAsFixed(1)} · ${data.meal.time}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTokens.ink,
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
  const _IngredientsEmptyState();

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
