import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../meals/models/meal.dart';
import '../../meals/providers/meals_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/services/claude_service.dart';

final dailyHeroRecipesProvider =
    AsyncNotifierProvider<DailyHeroRecipesNotifier, List<Meal>>(
  DailyHeroRecipesNotifier.new,
);

class DailyHeroRecipesNotifier extends AsyncNotifier<List<Meal>> {
  static const _keyLastUpdated = 'hero_recipes_last_updated_ms';
  static const _keyJson = 'hero_recipes_json';
  static const _refreshIntervalMs = 48 * 60 * 60 * 1000;

  @override
  Future<List<Meal>> build() => _loadOrRefresh();

  Future<List<Meal>> _loadOrRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_keyLastUpdated);
    final cached = prefs.getString(_keyJson);

    if (lastMs != null && cached != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
      if (elapsed < _refreshIntervalMs) {
        try {
          final raw = jsonDecode(cached) as List<dynamic>;
          return raw
              .map((e) => Meal.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {
          // Cache corrompu — on régénère.
        }
      }
    }

    return _generate(prefs);
  }

  Future<List<Meal>> _generate([SharedPreferences? existingPrefs]) async {
    final ingredients = ref.read(detectedIngredientsProvider);
    if (ingredients.isEmpty) return [];

    final profile = ref.read(userProfileProvider);
    final meals = await ClaudeService().findRecipes(
      ingredients,
      profile: profile,
    );

    final prefs = existingPrefs ?? await SharedPreferences.getInstance();
    await prefs.setInt(
        _keyLastUpdated, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(
        _keyJson, jsonEncode(meals.map((m) => m.toJson()).toList()));

    return meals;
  }

  Future<void> forceRefresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _generate());
  }
}
