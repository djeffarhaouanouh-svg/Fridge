import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
import '../data/mock_data.dart';
import '../../../core/services/neon_service.dart';
import '../../plan/models/day_plan.dart';

enum ScanStatus { idle, loading, done, error }

enum PlanStatus { idle, loading, done, error }

final capturedPhotosProvider = StateProvider<List<Uint8List>>((ref) => []);

final planStatusProvider = StateProvider<PlanStatus>((ref) => PlanStatus.idle);

final weekPlanProvider = StateProvider<List<DayPlan>>((ref) => []);

final scanStatusProvider = StateProvider<ScanStatus>((ref) => ScanStatus.idle);

final detectedIngredientsProvider = StateProvider<List<String>>((ref) => []);

final mealsProvider = StateNotifierProvider<MealsNotifier, List<Meal>>((ref) {
  return MealsNotifier();
});

class MealsNotifier extends StateNotifier<List<Meal>> {
  final _db = NeonService();

  MealsNotifier() : super(MockData.meals);

  /// À appeler après connexion : réaffiche les cœurs depuis la table `favorites`.
  Future<void> hydrateFavorites() async {
    try {
      final ids = await _db.getFavoriteIds();
      if (ids.isEmpty) return;
      final set = ids.toSet();
      state = [
        for (final m in state)
          m.copyWith(isFavorite: set.contains(m.id)),
      ];
    } catch (_) {}
  }

  void setMeals(List<Meal> meals) {
    state = meals;
  }

  void toggleFavorite(String mealId) {
    state = [
      for (final meal in state)
        if (meal.id == mealId)
          meal.copyWith(isFavorite: !meal.isFavorite)
        else
          meal,
    ];
    final meal = state.where((m) => m.id == mealId).firstOrNull;
    if (meal == null) return;
    if (meal.isFavorite) {
      _db.saveFavorite(meal).catchError((_) {});
    } else {
      _db.removeFavorite(mealId).catchError((_) {});
    }
  }

  List<Meal> getFavorites() {
    return state.where((meal) => meal.isFavorite).toList();
  }
}

final favoriteMealsProvider = Provider<List<Meal>>((ref) {
  final meals = ref.watch(mealsProvider);
  return meals.where((meal) => meal.isFavorite).toList();
});

final selectedMealProvider = StateProvider<Meal?>((ref) => null);

final recentlyViewedProvider = StateProvider<List<Meal>>((ref) => []);

// Clé : "${isoDate}_${mealType}", ex: "2026-05-03_Petit-déj"
final planMealSelectionsProvider = StateProvider<Map<String, Meal>>((ref) => {});
