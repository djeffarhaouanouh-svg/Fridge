import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  const UserProfile({
    this.name = '',
    this.email = '',
    this.objective,
    this.cookingLevel = CookingLevel.beginner,
    this.allergies = const {'Aucune'},
    this.diets = const {'Aucun'},
    this.kitchenEquipments = const {},
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
    Set<String>? kitchenEquipments,
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
        cookingLevel: _parseLevel(userRow?['cooking_level'] as String?),
        objective: _parseObjective(goalStr),
        allergies: Set<String>.from(allergies),
        diets: Set<String>.from(diets),
        kitchenEquipments: Set<String>.from(kitchenEquipments),
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
    } catch (e, st) {
      debugPrint('UserProfile setObjective: $e\n$st');
    }
  }

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
