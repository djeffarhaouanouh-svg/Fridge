import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/recipe_ids.dart';
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
final latestScanIngredientsProvider = StateProvider<List<String>>((ref) => []);
final latestScanMealsProvider = StateProvider<List<Meal>>((ref) => []);

final mealsProvider = StateNotifierProvider<MealsNotifier, List<Meal>>((ref) {
  return MealsNotifier();
});

class MealsNotifier extends StateNotifier<List<Meal>> {
  final _db = NeonService();

  MealsNotifier() : super([]);

  /// Catalogue Neon (favoris / plan / cuisiné) + recettes de scan persistées (`scan_meals_json`).
  Future<void> loadFromDatabase() async {
    try {
      final catalog = await _db.loadUserRecipesCatalog();
      final scanPersisted = await _db.loadScanMeals();
      final byId = <String, Meal>{};
      for (final m in scanPersisted) {
        final id = normalizeRecipeId(m.id);
        byId[id] = m.copyWith(id: id);
      }
      for (final m in catalog) {
        final id = normalizeRecipeId(m.id);
        byId[id] = m.copyWith(id: id);
      }
      final merged = byId.values.toList()
        ..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      state = merged;
    } catch (e, st) {
      debugPrint('MealsNotifier loadFromDatabase: $e\n$st');
    }
  }

  /// Fusionne les recettes du scan en mémoire et les enregistre dans Neon.
  Future<void> mergeScanResultsAndPersist(List<Meal> incoming) async {
    final map = {for (final m in state) m.id: m};
    for (final m in incoming) {
      final id = normalizeRecipeId(m.id);
      map[id] = m.copyWith(id: id);
    }
    state = map.values.toList();
    try {
      final normalized = incoming
          .map((m) => m.copyWith(id: normalizeRecipeId(m.id)))
          .toList();
      await _db.mergeAndSaveScanMeals(normalized);
    } catch (e, st) {
      debugPrint('mergeScanResultsAndPersist: $e\n$st');
    }
  }

  Future<void> toggleFavorite(String mealId) async {
    final nid = normalizeRecipeId(mealId);
    final current = state.where((m) => m.id == nid).firstOrNull;
    if (current == null) return;
    final becomingFavorite = !current.isFavorite;
    try {
      if (becomingFavorite) {
        await _db.saveFavorite(current.copyWith(isFavorite: true));
      } else {
        await _db.removeFavorite(nid);
      }
      await loadFromDatabase();
    } catch (e, st) {
      debugPrint('MealsNotifier toggleFavorite: $e\n$st');
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
