import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../meals/models/meal.dart';
import '../../../core/services/neon_service.dart';

final dailyHeroRecipesProvider =
    AsyncNotifierProvider<DailyHeroRecipesNotifier, List<Meal>>(
  DailyHeroRecipesNotifier.new,
);

final marmitonBudgetRecipesProvider = FutureProvider<List<Meal>>((ref) async {
  final db = NeonService();
  return db.loadMarmitonRecipes(limit: 3);
});

class DailyHeroRecipesNotifier extends AsyncNotifier<List<Meal>> {
  final _db = NeonService();

  @override
  Future<List<Meal>> build() => _loadOrRefresh();

  Future<List<Meal>> _loadOrRefresh() async => _generate();

  Future<List<Meal>> _generate() async {
    final meals = _homeBudgetMeals;
    await _db.saveHeroRecipes(meals);
    return meals;
  }

  Future<void> forceRefresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _generate());
  }
}

final List<Meal> _homeBudgetMeals = [
  Meal(
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
  Meal(
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
    color: '#F2C94C',
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
    prepTimeMin: 4,
    cookTimeMin: 12,
  ),
  Meal(
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
    color: '#6FCF97',
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
    prepTimeMin: 7,
    cookTimeMin: 13,
  ),
];
