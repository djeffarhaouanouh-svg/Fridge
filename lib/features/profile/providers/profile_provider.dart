import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/neon_service.dart';
import '../../../core/services/user_service.dart';

enum CookingObjective { weightLoss, muscleGain, family, passion }
enum CookingLevel { beginner, intermediate, advanced, expert }

class UserProfile {
  final String name;
  final String email;
  final CookingObjective? objective;
  final CookingLevel? cookingLevel;
  final Set<String> allergies;
  final Set<String> diets;
  // Notifications
  final bool notifExpiry;
  final bool notifSuggestion;
  final bool notifFridge;
  // Nutrition targets
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFats;

  const UserProfile({
    this.name = 'Thomas',
    this.email = 'thomas@fridge.ai',
    this.objective,
    this.cookingLevel,
    this.allergies = const {},
    this.diets = const {},
    this.notifExpiry = true,
    this.notifSuggestion = true,
    this.notifFridge = true,
    this.targetCalories = 2000,
    this.targetProtein = 150,
    this.targetCarbs = 200,
    this.targetFats = 65,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    Object? objective = _s,
    Object? cookingLevel = _s,
    Set<String>? allergies,
    Set<String>? diets,
    bool? notifExpiry,
    bool? notifSuggestion,
    bool? notifFridge,
    int? targetCalories,
    int? targetProtein,
    int? targetCarbs,
    int? targetFats,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      objective: objective == _s ? this.objective : objective as CookingObjective?,
      cookingLevel: cookingLevel == _s ? this.cookingLevel : cookingLevel as CookingLevel?,
      allergies: allergies ?? this.allergies,
      diets: diets ?? this.diets,
      notifExpiry: notifExpiry ?? this.notifExpiry,
      notifSuggestion: notifSuggestion ?? this.notifSuggestion,
      notifFridge: notifFridge ?? this.notifFridge,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFats: targetFats ?? this.targetFats,
    );
  }

  static const _s = Object();
}

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final _db = NeonService();

  UserProfileNotifier() : super(const UserProfile()) {
    _init();
  }

  Future<void> _init() async {
    final info = await UserService().fetchUser();
    state = state.copyWith(name: info.name, email: info.email);
    try {
      await _db.initDb();
      final rows = await _db.query(
        "SELECT * FROM user_profiles WHERE id = 'default'",
      );
      if (rows.isNotEmpty) {
        final r = rows.first;
        state = state.copyWith(
          objective: _parseObjective(r['objective'] as String?),
          cookingLevel: _parseLevel(r['cooking_level'] as String?),
          allergies: Set<String>.from((r['allergies'] as List? ?? [])),
          diets: Set<String>.from((r['diets'] as List? ?? [])),
          targetCalories: r['target_calories'] as int? ?? 2000,
          targetProtein: r['target_protein'] as int? ?? 150,
          targetCarbs: r['target_carbs'] as int? ?? 200,
          targetFats: r['target_fats'] as int? ?? 65,
        );
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      await _db.execute('''
        INSERT INTO user_profiles (id, objective, cooking_level, allergies, diets,
          target_calories, target_protein, target_carbs, target_fats, updated_at)
        VALUES (\$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,NOW())
        ON CONFLICT (id) DO UPDATE SET
          objective=EXCLUDED.objective, cooking_level=EXCLUDED.cooking_level,
          allergies=EXCLUDED.allergies, diets=EXCLUDED.diets,
          target_calories=EXCLUDED.target_calories, target_protein=EXCLUDED.target_protein,
          target_carbs=EXCLUDED.target_carbs, target_fats=EXCLUDED.target_fats,
          updated_at=NOW()
      ''', [
        'default',
        state.objective?.name,
        state.cookingLevel?.name,
        state.allergies.toList(),
        state.diets.toList(),
        state.targetCalories,
        state.targetProtein,
        state.targetCarbs,
        state.targetFats,
      ]);
    } catch (_) {}
  }

  CookingObjective? _parseObjective(String? v) =>
      v == null ? null : CookingObjective.values.where((e) => e.name == v).firstOrNull;

  CookingLevel? _parseLevel(String? v) =>
      v == null ? null : CookingLevel.values.where((e) => e.name == v).firstOrNull;

  void setObjective(CookingObjective obj) {
    state = state.copyWith(objective: state.objective == obj ? null : obj);
    _save();
  }

  void setCookingLevel(CookingLevel level) {
    state = state.copyWith(cookingLevel: level);
    _save();
  }

  void toggleAllergy(String v) {
    final s = Set<String>.from(state.allergies);
    s.contains(v) ? s.remove(v) : s.add(v);
    state = state.copyWith(allergies: s);
    _save();
  }

  void toggleDiet(String v) {
    final s = Set<String>.from(state.diets);
    s.contains(v) ? s.remove(v) : s.add(v);
    state = state.copyWith(diets: s);
    _save();
  }

  void setNotif({bool? expiry, bool? suggestion, bool? fridge}) =>
      state = state.copyWith(
        notifExpiry: expiry,
        notifSuggestion: suggestion,
        notifFridge: fridge,
      );

  void setNutrition({int? calories, int? protein, int? carbs, int? fats}) {
    state = state.copyWith(
      targetCalories: calories,
      targetProtein: protein,
      targetCarbs: carbs,
      targetFats: fats,
    );
    _save();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(),
);
