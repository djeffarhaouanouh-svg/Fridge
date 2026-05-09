import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Recettes adaptées via "Adapter avec mes ingrédients" — persiste entre sessions.
final adaptedMealsProvider =
    StateNotifierProvider<AdaptedMealsNotifier, List<Meal>>(
  (ref) => AdaptedMealsNotifier(),
);

class AdaptedMealsNotifier extends StateNotifier<List<Meal>> {
  static const _prefKey = 'adapted_meals_json';
  final _db = NeonService();

  AdaptedMealsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    // Cache local d'abord pour affichage immédiat
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        state = list.map(Meal.fromJson).toList();
      }
    } catch (_) {}
    // Puis synchronise depuis Neon
    try {
      final remote = await _db.loadAdaptedMeals();
      if (remote.isNotEmpty) {
        state = remote;
        _saveToPrefs();
      }
    } catch (_) {}
  }

  Future<void> addAdapted(Meal meal) async {
    if (state.any((m) => m.id == meal.id)) return;
    state = [meal, ...state];
    _saveToPrefs();
    try {
      await _db.saveAdaptedMeals(state);
    } catch (_) {}
  }

  void _saveToPrefs() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefKey, jsonEncode(state.map((m) => m.toJson()).toList()));
    });
  }
}

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
    final currentIndex = state.indexWhere((m) => m.id == nid);
    if (currentIndex < 0) return;
    final current = state[currentIndex];
    if (current == null) return;
    final becomingFavorite = !current.isFavorite;
    final optimistic = current.copyWith(isFavorite: becomingFavorite);

    // Optimistic UI: l'icône change immédiatement au premier tap.
    final nextState = List<Meal>.from(state);
    nextState[currentIndex] = optimistic;
    state = nextState;

    try {
      if (becomingFavorite) {
        await _db.saveFavorite(optimistic);
      } else {
        await _db.removeFavorite(nid);
      }
    } catch (e, st) {
      // Rollback local si l'écriture distante échoue.
      final rollback = List<Meal>.from(state);
      final idx = rollback.indexWhere((m) => m.id == nid);
      if (idx >= 0) rollback[idx] = current;
      state = rollback;
      debugPrint('MealsNotifier toggleFavorite: $e\n$st');
    }
  }

  List<Meal> getFavorites() {
    return state.where((meal) => meal.isFavorite).toList();
  }

  Future<void> removeMeal(String mealId) async {
    final nid = normalizeRecipeId(mealId);
    final updated = state.where((m) => m.id != nid).toList();
    state = updated;
    try {
      final encoded = jsonEncode(
        updated.where((m) => !m.isFavorite).map((m) => m.toJson()).toList(),
      );
      await _db.execute(
        'UPDATE users SET scan_meals_json = \$1 WHERE id = \$2',
        [encoded, NeonService.kUserId],
      );
    } catch (e, st) {
      debugPrint('removeMeal: $e\n$st');
    }
  }
}

final favoriteMealsProvider = Provider<List<Meal>>((ref) {
  final meals = ref.watch(mealsProvider);
  return meals.where((meal) => meal.isFavorite).toList();
});

final selectedMealProvider = StateProvider<Meal?>((ref) => null);

final recentlyViewedProvider = StateProvider<List<Meal>>((ref) => []);

/// À l’ouverture d’une fiche recette : met à jour « Dernières recettes » du profil.
void registerRecentlyViewed(WidgetRef ref, Meal meal) {
  final id = normalizeRecipeId(meal.id);
  final catalog = ref.read(mealsProvider);
  Meal resolved = meal;
  for (final m in catalog) {
    if (normalizeRecipeId(m.id) == id) {
      resolved = m;
      break;
    }
  }
  final prev = ref.read(recentlyViewedProvider);
  final rest = prev.where((m) => normalizeRecipeId(m.id) != id).toList();
  final next = [resolved, ...rest];
  const maxItems = 20;
  ref.read(recentlyViewedProvider.notifier).state =
      next.length > maxItems ? next.sublist(0, maxItems) : next;
}

// Clé : "${isoDate}_${mealType}", ex: "2026-05-03_Petit-déj"
final planMealSelectionsProvider = StateProvider<Map<String, Meal>>((ref) => {});

// Photos custom ajoutées sur un créneau du planning (clé identique)
final planSlotPhotosProvider = StateProvider<Map<String, Uint8List>>((ref) => {});

// Résultats d'analyse IA par créneau
final planSlotAnalysisProvider =
    StateProvider<Map<String, Map<String, dynamic>>>((ref) => {});
