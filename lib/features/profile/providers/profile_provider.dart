import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  UserProfileNotifier() : super(const UserProfile()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final info = await UserService().fetchUser();
    state = state.copyWith(name: info.name, email: info.email);
  }

  void setObjective(CookingObjective obj) =>
      state = state.copyWith(objective: state.objective == obj ? null : obj);

  void setCookingLevel(CookingLevel level) =>
      state = state.copyWith(cookingLevel: level);

  void toggleAllergy(String v) {
    final s = Set<String>.from(state.allergies);
    s.contains(v) ? s.remove(v) : s.add(v);
    state = state.copyWith(allergies: s);
  }

  void toggleDiet(String v) {
    final s = Set<String>.from(state.diets);
    s.contains(v) ? s.remove(v) : s.add(v);
    state = state.copyWith(diets: s);
  }

  void setNotif({bool? expiry, bool? suggestion, bool? fridge}) =>
      state = state.copyWith(
        notifExpiry: expiry,
        notifSuggestion: suggestion,
        notifFridge: fridge,
      );

  void setNutrition({int? calories, int? protein, int? carbs, int? fats}) =>
      state = state.copyWith(
        targetCalories: calories,
        targetProtein: protein,
        targetCarbs: carbs,
        targetFats: fats,
      );
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(),
);
