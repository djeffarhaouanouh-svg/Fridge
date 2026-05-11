import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../meals/models/meal.dart';
import '../../meals/providers/meals_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/services/claude_service.dart';
import '../../../core/services/neon_service.dart';

final dailyHeroRecipesProvider =
    AsyncNotifierProvider<DailyHeroRecipesNotifier, List<Meal>>(
  DailyHeroRecipesNotifier.new,
);

final marmitonBudgetRecipesProvider = FutureProvider<List<Meal>>((ref) async {
  final db = NeonService();
  return db.loadMarmitonRecipes(limit: 20);
});

final sportRecipesProvider = FutureProvider<List<Meal>>((ref) async {
  final db = NeonService();
  try {
    final results = await db.loadRecipesV2(category: 'Sport', limit: 10);
    if (results.isNotEmpty) return results;
    return await db.loadRecipesV2(limit: 10);
  } catch (_) {
    return [];
  }
});

final minceurRecipesProvider = FutureProvider<List<Meal>>((ref) async {
  final db = NeonService();
  try {
    final results = await db.loadRecipesV3(category: 'Minceur', limit: 10);
    if (results.isNotEmpty) return results;
    return await db.loadRecipesV3(limit: 10);
  } catch (_) {
    return [];
  }
});

class DailyHeroRecipesNotifier extends AsyncNotifier<List<Meal>> {
  static const _refreshIntervalHours = 48;
  final _db = NeonService();

  @override
  Future<List<Meal>> build() => _loadOrRefresh();

  Future<List<Meal>> _loadOrRefresh() async {
    final ingredients = ref.read(detectedIngredientsProvider);
    if (ingredients.isEmpty) return [];

    try {
      final cached = await _db.loadHeroRecipes();
      if (cached != null) {
        final elapsed =
            DateTime.now().toUtc().difference(cached.refreshedAt.toUtc());
        if (elapsed.inHours < _refreshIntervalHours) return cached.meals;
      }
    } catch (_) {
      // Echec réseau — on tente quand même de générer.
    }

    return _generate();
  }

  Future<List<Meal>> _generate() async {
    final ingredients = ref.read(detectedIngredientsProvider);
    if (ingredients.isEmpty) return [];

    final profile = ref.read(userProfileProvider);
    final meals = await ClaudeService().findRecipes(
      ingredients,
      profile: profile,
      neonService: _db,
    );

    await _db.saveHeroRecipes(meals);
    return meals;
  }

  Future<void> forceRefresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _generate());
  }
}
