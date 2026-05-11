import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/neon_service.dart';
import '../../../core/services/user_service.dart';

enum CookingObjective { weightLoss, muscleGain, healthy, learn, maintain }
enum CookingLevel { beginner, intermediate, advanced, expert }
enum AiTone { coach, chef, ami }
enum ThemePreference { light, dark }

class UserPhotoEntry {
  final String id;
  final String base64;
  final String? createdAt;

  const UserPhotoEntry({
    required this.id,
    required this.base64,
    this.createdAt,
  });
}

class UserProfile {
  final String name;
  final String email;
  final CookingObjective? objective;
  final CookingLevel? cookingLevel;
  final Set<String> allergies;
  final Set<String> diets;
  final Set<String> kitchenEquipments;
  final bool notifExpiry;
  final bool notifSuggestion;
  final bool notifFridge;
  final int targetCalories;
  final int targetProtein;
  final int targetCarbs;
  final int targetFats;
  final String? gender;        // 'homme' or 'femme'
  final int? age;
  final double? currentWeight; // kg
  final double? targetWeight;  // kg

  const UserProfile({
    this.name = '',
    this.email = '',
    this.objective,
    this.cookingLevel = CookingLevel.beginner,
    this.allergies = const {'Aucune'},
    this.diets = const {'Aucun'},
    this.kitchenEquipments = const {'Four', 'Micro-ondes'},
    this.notifExpiry = true,
    this.notifSuggestion = true,
    this.notifFridge = true,
    this.targetCalories = 2000,
    this.targetProtein = 150,
    this.targetCarbs = 200,
    this.targetFats = 65,
    this.gender,
    this.age,
    this.currentWeight,
    this.targetWeight,
  });

  UserProfile copyWith({
    String? name,
    String? email,
    Object? objective = _s,
    Object? cookingLevel = _s,
    Set<String>? allergies,
    Set<String>? diets,
    Set<String>? kitchenEquipments,
    bool? notifExpiry,
    bool? notifSuggestion,
    bool? notifFridge,
    int? targetCalories,
    int? targetProtein,
    int? targetCarbs,
    int? targetFats,
    Object? gender = _s,
    Object? age = _s,
    Object? currentWeight = _s,
    Object? targetWeight = _s,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      objective:
          objective == _s ? this.objective : objective as CookingObjective?,
      cookingLevel:
          cookingLevel == _s ? this.cookingLevel : cookingLevel as CookingLevel?,
      allergies: allergies ?? this.allergies,
      diets: diets ?? this.diets,
      kitchenEquipments: kitchenEquipments ?? this.kitchenEquipments,
      notifExpiry: notifExpiry ?? this.notifExpiry,
      notifSuggestion: notifSuggestion ?? this.notifSuggestion,
      notifFridge: notifFridge ?? this.notifFridge,
      targetCalories: targetCalories ?? this.targetCalories,
      targetProtein: targetProtein ?? this.targetProtein,
      targetCarbs: targetCarbs ?? this.targetCarbs,
      targetFats: targetFats ?? this.targetFats,
      gender: gender == _s ? this.gender : gender as String?,
      age: age == _s ? this.age : age as int?,
      currentWeight: currentWeight == _s ? this.currentWeight : currentWeight as double?,
      targetWeight: targetWeight == _s ? this.targetWeight : targetWeight as double?,
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

    // Load body data from SharedPreferences (local only)
    try {
      final prefs = await SharedPreferences.getInstance();
      state = state.copyWith(
        gender: prefs.getString('user_gender'),
        age: prefs.getInt('user_age'),
        currentWeight: prefs.getDouble('user_weight'),
        targetWeight: prefs.getDouble('user_target_weight'),
      );
    } catch (_) {}

    try {
      await _db.upsertUser(info.name, info.email);
      final p = await _db.loadProfile();

      final userRow = p['user'] as Map<String, dynamic>?;
      final nutRow = p['nutrition'] as Map<String, dynamic>?;
      final goalStr = p['goal'] as String?;
      final allergies = (p['allergies'] as List).cast<String>();
      final diets = (p['diets'] as List).cast<String>();
      final kitchenEquipments = (p['kitchenEquipments'] as List).cast<String>();
      final notifRow = p['notifications'] as Map<String, dynamic>?;

      state = state.copyWith(
        cookingLevel: _parseLevel(userRow?['cooking_level'] as String?) ?? CookingLevel.beginner,
        objective: _parseObjective(goalStr),
        allergies: allergies.isEmpty ? const {'Aucune'} : Set<String>.from(allergies),
        diets: diets.isEmpty ? const {'Aucun'} : Set<String>.from(diets),
        kitchenEquipments: kitchenEquipments.isEmpty ? const {'Four', 'Micro-ondes'} : Set<String>.from(kitchenEquipments),
        targetCalories: nutRow?['calories'] as int? ?? 2000,
        targetProtein: nutRow?['proteins'] as int? ?? 150,
        targetCarbs: nutRow?['carbs'] as int? ?? 200,
        targetFats: nutRow?['fats'] as int? ?? 65,
        notifExpiry: notifRow?['notif_expiry'] as bool? ?? true,
        notifSuggestion: notifRow?['notif_suggestion'] as bool? ?? true,
        notifFridge: notifRow?['notif_fridge'] as bool? ?? true,
      );
    } catch (e, st) {
      debugPrint('UserProfile _init: $e\n$st');
    }
  }

  // ── Setters ────────────────────────────────────────────────────────────────

  Future<void> setObjective(CookingObjective obj) async {
    final next = state.objective == obj ? null : obj;
    state = state.copyWith(objective: next);
    try {
      await _db.saveGoal(_objectiveToDb(next));
      // Recalculate calories when objective changes (if body data is available)
      final g = state.gender;
      final a = state.age;
      final w = state.currentWeight;
      if (g != null && a != null && w != null) {
        final cal = calcCalories(gender: g, age: a, weight: w, objective: next);
        final pro = calcProtein(weight: w, objective: next);
        final fat = calcFats(cal);
        await setNutrition(
          calories: cal,
          protein: pro,
          carbs: calcCarbs(calories: cal, protein: pro, fats: fat),
          fats: fat,
        );
      }
    } catch (e, st) {
      debugPrint('UserProfile setObjective: $e\n$st');
    }
  }

  Future<void> setBodyData({
    required String gender,
    required int age,
    required double weight,
    required double targetWeight,
  }) async {
    state = state.copyWith(
      gender: gender,
      age: age,
      currentWeight: weight,
      targetWeight: targetWeight,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_gender', gender);
      await prefs.setInt('user_age', age);
      await prefs.setDouble('user_weight', weight);
      await prefs.setDouble('user_target_weight', targetWeight);

      final cal = calcCalories(gender: gender, age: age, weight: weight, objective: state.objective);
      final pro = calcProtein(weight: weight, objective: state.objective);
      final fat = calcFats(cal);
      await setNutrition(
        calories: cal,
        protein: pro,
        carbs: calcCarbs(calories: cal, protein: pro, fats: fat),
        fats: fat,
      );
    } catch (e, st) {
      debugPrint('UserProfile setBodyData: $e\n$st');
    }
  }

  // ── Calorie calculation helpers ────────────────────────────────────────────

  // Harris-Benedict + activity 1.375, average height (175 cm homme / 163 cm femme)
  static int calcCalories({
    required String gender,
    required int age,
    required double weight,
    CookingObjective? objective,
  }) {
    final double bmr = gender == 'homme'
        ? 66.47 + (13.75 * weight) + (5.0 * 175) - (6.75 * age)
        : 655.1 + (9.56 * weight) + (1.85 * 163) - (4.68 * age);
    double tdee = bmr * 1.375;
    switch (objective) {
      case CookingObjective.weightLoss:
        tdee -= 500;
        break;
      case CookingObjective.muscleGain:
        tdee += 300;
        break;
      default:
        break;
    }
    return tdee.round().clamp(1200, 4000);
  }

  static int calcProtein({required double weight, CookingObjective? objective}) {
    final double gPerKg = switch (objective) {
      CookingObjective.muscleGain => 1.8,
      CookingObjective.weightLoss => 1.6,
      _ => 1.4,
    };
    return (weight * gPerKg).round().clamp(80, 250);
  }

  static int calcFats(int calories) =>
      ((calories * 0.28) / 9).round().clamp(40, 120);

  static int calcCarbs({required int calories, required int protein, required int fats}) =>
      ((calories - protein * 4 - fats * 9) / 4).round().clamp(50, 400);

  Future<void> setCookingLevel(CookingLevel level) async {
    state = state.copyWith(cookingLevel: level);
    try {
      await _db.saveCookingLevel(_levelToDb(level));
    } catch (e, st) {
      debugPrint('UserProfile setCookingLevel: $e\n$st');
    }
  }

  Future<void> toggleAllergy(String v) async {
    final s = Set<String>.from(state.allergies);
    if (v == 'Aucune') {
      if (s.contains(v)) {
        s.remove(v);
      } else {
        s.clear();
        s.add(v);
      }
    } else {
      s.remove('Aucune');
      s.contains(v) ? s.remove(v) : s.add(v);
    }
    state = state.copyWith(allergies: s);
    try {
      await _db.saveAllergies(s.toList());
    } catch (e, st) {
      debugPrint('UserProfile toggleAllergy: $e\n$st');
    }
  }

  Future<void> toggleDiet(String v) async {
    final s = Set<String>.from(state.diets);
    if (v == 'Aucun') {
      if (s.contains(v)) {
        s.remove(v);
      } else {
        s.clear();
        s.add(v);
      }
    } else {
      s.remove('Aucun');
      s.contains(v) ? s.remove(v) : s.add(v);
    }
    state = state.copyWith(diets: s);
    try {
      await _db.saveDiets(s.toList());
    } catch (e, st) {
      debugPrint('UserProfile toggleDiet: $e\n$st');
    }
  }

  Future<void> toggleKitchenEquipment(String v) async {
    final s = Set<String>.from(state.kitchenEquipments);
    s.contains(v) ? s.remove(v) : s.add(v);
    state = state.copyWith(kitchenEquipments: s);
    try {
      await _db.saveKitchenEquipments(s.toList());
    } catch (e, st) {
      debugPrint('UserProfile toggleKitchenEquipment: $e\n$st');
    }
  }

  Future<void> setNotif({bool? expiry, bool? suggestion, bool? fridge}) async {
    state = state.copyWith(
      notifExpiry: expiry,
      notifSuggestion: suggestion,
      notifFridge: fridge,
    );
    try {
      await _db.saveNotifications(
        state.notifExpiry,
        state.notifSuggestion,
        state.notifFridge,
      );
    } catch (e, st) {
      debugPrint('UserProfile setNotif: $e\n$st');
    }
  }

  Future<void> updateName(String name) async {
    state = state.copyWith(name: name);
    try {
      await _db.upsertUser(name, state.email);
      await AuthService.updateName(NeonService.kUserId, name);
    } catch (e, st) {
      debugPrint('UserProfile updateName: $e\n$st');
    }
  }

  Future<String?> updateEmail(String email) async {
    final nextEmail = email.trim().toLowerCase();
    if (nextEmail.isEmpty) return 'Email invalide.';
    try {
      final exists = await _db.query(
        '''
        SELECT id::text
        FROM users
        WHERE lower(email) = lower(\$1)
          AND id <> \$2::uuid
        LIMIT 1
        ''',
        [nextEmail, NeonService.kUserId],
      );
      if (exists.isNotEmpty) {
        return 'Cet email est deja utilise.';
      }

      state = state.copyWith(email: nextEmail);
      await _db.upsertUser(state.name, nextEmail);
      await AuthService.updateEmail(NeonService.kUserId, nextEmail);
      return null;
    } catch (e, st) {
      debugPrint('UserProfile updateEmail: $e\n$st');
      return 'Impossible de modifier l\'email.';
    }
  }

  Future<void> setNutrition({int? calories, int? protein, int? carbs, int? fats}) async {
    state = state.copyWith(
      targetCalories: calories,
      targetProtein: protein,
      targetCarbs: carbs,
      targetFats: fats,
    );
    try {
      await _db.saveNutrition(
        state.targetCalories,
        state.targetProtein,
        state.targetCarbs,
        state.targetFats,
      );
    } catch (e, st) {
      debugPrint('UserProfile setNutrition: $e\n$st');
    }
  }

  // ── Mapping helpers ────────────────────────────────────────────────────────

  static String? _objectiveToDb(CookingObjective? o) => switch (o) {
        CookingObjective.weightLoss => 'perte_poids',
        CookingObjective.muscleGain => 'prise_masse',

        CookingObjective.healthy => 'manger_sainement',
        CookingObjective.learn => 'apprendre_cuisiner',
        CookingObjective.maintain => 'garder_ligne',
        null => null,
      };

  static CookingObjective? _parseObjective(String? v) => switch (v) {
        'perte_poids' => CookingObjective.weightLoss,
        'prise_masse' => CookingObjective.muscleGain,

        'manger_sainement' => CookingObjective.healthy,
        'apprendre_cuisiner' => CookingObjective.learn,
        'garder_ligne' => CookingObjective.maintain,
        _ => null,
      };

  static String _levelToDb(CookingLevel l) => switch (l) {
        CookingLevel.beginner => 'debutant',
        CookingLevel.intermediate => 'intermediaire',
        CookingLevel.advanced => 'avance',
        CookingLevel.expert => 'expert',
      };

  static CookingLevel? _parseLevel(String? v) => switch (v) {
        'debutant' => CookingLevel.beginner,
        'intermediaire' => CookingLevel.intermediate,
        'avance' => CookingLevel.advanced,
        'expert' => CookingLevel.expert,
        _ => null,
      };
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>(
  (ref) => UserProfileNotifier(),
);

final aiToneProvider = StateProvider<AiTone>((ref) => AiTone.chef);
final themePreferenceProvider =
    StateProvider<ThemePreference>((ref) => ThemePreference.light);

final userPhotosProvider = FutureProvider<List<UserPhotoEntry>>((ref) async {
  final rows = await NeonService().loadUserPhotos();
  return rows
      .map(
        (r) => UserPhotoEntry(
          id: (r['id'] as String?) ?? '',
          base64: (r['photo_base64'] as String?) ?? '',
          createdAt: r['created_at'] as String?,
        ),
      )
      .where((p) => p.id.isNotEmpty && p.base64.isNotEmpty)
      .toList(growable: false);
});
