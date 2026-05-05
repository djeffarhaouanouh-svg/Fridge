import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal.dart';
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

  MealsNotifier() : super([]);

  /// Recettes persistées (Neon) + entrées locales pas encore en base (ex. dernier scan).
  Future<void> loadFromDatabase() async {
    try {
      final dbMeals = await _db.loadUserRecipesCatalog();
      final dbIds = dbMeals.map((m) => m.id).toSet();
      final ephemeral = state.where((m) => !dbIds.contains(m.id)).toList();
      state = [...dbMeals, ...ephemeral];
    } catch (_) {}
  }

  /// Fusionne les recettes proposées après scan sans effacer le catalogue chargé depuis la DB.
  void mergeScanResults(List<Meal> incoming) {
    final map = {for (final m in state) m.id: m};
    for (final m in incoming) {
      map[m.id] = m;
    }
    state = map.values.toList();
  }

  Future<void> toggleFavorite(String mealId) async {
    final current = state.where((m) => m.id == mealId).firstOrNull;
    if (current == null) return;
    final becomingFavorite = !current.isFavorite;
    try {
      if (becomingFavorite) {
        await _db.saveFavorite(current.copyWith(isFavorite: true));
      } else {
        await _db.removeFavorite(mealId);
      }
      await loadFromDatabase();
    } catch (_) {}
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
