import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../features/meals/models/meal.dart';
import '../config/app_secrets.dart';

class NeonService {
  static const _host = 'ep-dawn-night-abd29yl2-pooler.eu-west-2.aws.neon.tech';
  static const _user = 'neondb_owner';
  static const _uuidNamespace = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  // UUID v5 dérivé du Firebase UID → toujours le même UUID pour le même compte
  static String get kUserId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return '00000000-0000-0000-0000-000000000001';
    return const Uuid().v5(_uuidNamespace, uid);
  }

  static String get _auth =>
      'Basic ${base64Encode(utf8.encode('$_user:$kNeonPassword'))}';

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic> params = const [],
  ]) async {
    final resp = await http.post(
      Uri.https(_host, '/sql'),
      headers: {
        'Authorization': _auth,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'query': sql, 'params': params}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Neon ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data['rows'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<void> execute(String sql, [List<dynamic> params = const []]) async {
    await query(sql, params);
  }

  // ── USERS ──────────────────────────────────────────────────────────────────

  Future<void> upsertUser(String name, String email) async {
    await execute('''
      INSERT INTO users (id, name, email)
      VALUES (\$1, \$2, \$3)
      ON CONFLICT (id) DO UPDATE SET
        name  = EXCLUDED.name,
        email = EXCLUDED.email
    ''', [kUserId, name, email]);
  }

  Future<void> saveCookingLevel(String level) async {
    await execute(
      'UPDATE users SET cooking_level = \$1 WHERE id = \$2',
      [level, kUserId],
    );
  }

  // ── NUTRITION ──────────────────────────────────────────────────────────────

  Future<void> saveNutrition(
      int calories, int proteins, int carbs, int fats) async {
    await execute(
        'DELETE FROM nutrition_profiles WHERE user_id = \$1', [kUserId]);
    await execute('''
      INSERT INTO nutrition_profiles (user_id, calories, proteins, carbs, fats)
      VALUES (\$1, \$2, \$3, \$4, \$5)
    ''', [kUserId, calories, proteins, carbs, fats]);
  }

  // ── GOALS ──────────────────────────────────────────────────────────────────

  Future<void> saveGoal(String? goal) async {
    await execute('DELETE FROM goals WHERE user_id = \$1', [kUserId]);
    if (goal != null) {
      await execute(
        'INSERT INTO goals (user_id, goal) VALUES (\$1, \$2)',
        [kUserId, goal],
      );
    }
  }

  // ── ALLERGIES ──────────────────────────────────────────────────────────────

  Future<void> saveAllergies(List<String> names) async {
    await execute(
        'DELETE FROM user_allergies WHERE user_id = \$1', [kUserId]);
    for (final name in names) {
      await execute(
        'INSERT INTO allergies (name) VALUES (\$1) ON CONFLICT (name) DO NOTHING',
        [name],
      );
      await execute('''
        INSERT INTO user_allergies (user_id, allergy_id)
        SELECT \$1, id FROM allergies WHERE name = \$2
        ON CONFLICT DO NOTHING
      ''', [kUserId, name]);
    }
  }

  // ── DIETS ──────────────────────────────────────────────────────────────────

  Future<void> saveDiets(List<String> names) async {
    await execute('DELETE FROM user_diets WHERE user_id = \$1', [kUserId]);
    for (final name in names) {
      await execute(
        'INSERT INTO diets (name) VALUES (\$1) ON CONFLICT (name) DO NOTHING',
        [name],
      );
      await execute('''
        INSERT INTO user_diets (user_id, diet_id)
        SELECT \$1, id FROM diets WHERE name = \$2
        ON CONFLICT DO NOTHING
      ''', [kUserId, name]);
    }
  }

  // ── NOTIFICATIONS ──────────────────────────────────────────────────────────

  Future<void> saveNotifications(
      bool expiry, bool suggestion, bool fridge) async {
    await execute('''
      INSERT INTO user_notifications (user_id, notif_expiry, notif_suggestion, notif_fridge)
      VALUES (\$1, \$2, \$3, \$4)
      ON CONFLICT (user_id) DO UPDATE SET
        notif_expiry      = EXCLUDED.notif_expiry,
        notif_suggestion  = EXCLUDED.notif_suggestion,
        notif_fridge      = EXCLUDED.notif_fridge
    ''', [kUserId, expiry, suggestion, fridge]);
  }

  // ── LOAD FULL PROFILE ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadProfile() async {
    final results = await Future.wait([
      query('SELECT name, email, cooking_level FROM users WHERE id = \$1',
          [kUserId]),
      query(
          'SELECT calories, proteins, carbs, fats FROM nutrition_profiles WHERE user_id = \$1',
          [kUserId]),
      query('SELECT goal FROM goals WHERE user_id = \$1', [kUserId]),
      query('''
        SELECT a.name FROM allergies a
        JOIN user_allergies ua ON ua.allergy_id = a.id
        WHERE ua.user_id = \$1
      ''', [kUserId]),
      query('''
        SELECT d.name FROM diets d
        JOIN user_diets ud ON ud.diet_id = d.id
        WHERE ud.user_id = \$1
      ''', [kUserId]),
      query(
          'SELECT notif_expiry, notif_suggestion, notif_fridge FROM user_notifications WHERE user_id = \$1',
          [kUserId]),
    ]);

    return {
      'user': results[0].firstOrNull,
      'nutrition': results[1].firstOrNull,
      'goal': results[2].firstOrNull?['goal'],
      'allergies': results[3].map((r) => r['name'] as String).toList(),
      'diets': results[4].map((r) => r['name'] as String).toList(),
      'notifications': results[5].firstOrNull,
    };
  }

  // ── RECIPES ────────────────────────────────────────────────────────────────

  Future<void> upsertRecipe(Meal meal) async {
    final duration =
        int.tryParse(meal.time.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final difficulty =
        meal.difficulty.replaceAll('é', 'e').replaceAll('è', 'e');

    await execute('''
      INSERT INTO recipes (
        id, title, image_url, duration, calories,
        difficulty, type, type_label, emoji, color, locked
      ) VALUES (\$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11)
      ON CONFLICT (id) DO UPDATE SET
        title     = EXCLUDED.title,
        image_url = EXCLUDED.image_url
    ''', [
      meal.id,
      meal.title,
      meal.photo,
      duration,
      meal.kcal,
      difficulty,
      meal.type,
      meal.typeLabel,
      meal.emoji,
      meal.color,
      meal.locked,
    ]);

    await execute(
        'DELETE FROM recipe_steps WHERE recipe_id = \$1', [meal.id]);
    for (int i = 0; i < meal.steps.length; i++) {
      await execute(
        'INSERT INTO recipe_steps (recipe_id, step_order, instruction) VALUES (\$1, \$2, \$3)',
        [meal.id, i + 1, meal.steps[i]],
      );
    }

    await execute(
        'DELETE FROM recipe_ingredients WHERE recipe_id = \$1', [meal.id]);
    for (final ing in meal.ingredients) {
      await execute(
        'INSERT INTO ingredients (name) VALUES (\$1) ON CONFLICT (name) DO NOTHING',
        [ing.name],
      );
      final qtyMatch = RegExp(r'^([\d.]+)').firstMatch(ing.qty.trim());
      final qty = qtyMatch != null ? double.tryParse(qtyMatch.group(1)!) : null;
      final unit = ing.qty.replaceFirst(RegExp(r'^[\d.]+\s*'), '').trim();
      await execute('''
        INSERT INTO recipe_ingredients (recipe_id, ingredient_id, quantity, unit)
        SELECT \$1, id, \$3, \$4 FROM ingredients WHERE name = \$2
      ''', [meal.id, ing.name, qty, unit]);
    }
  }

  // ── FAVORITES ──────────────────────────────────────────────────────────────

  Future<void> saveFavorite(Meal meal) async {
    await upsertRecipe(meal);
    await execute('''
      INSERT INTO favorites (user_id, recipe_id)
      VALUES (\$1, \$2)
      ON CONFLICT DO NOTHING
    ''', [kUserId, meal.id]);
  }

  Future<void> removeFavorite(String mealId) async {
    await execute(
      'DELETE FROM favorites WHERE user_id = \$1 AND recipe_id = \$2',
      [kUserId, mealId],
    );
  }

  Future<List<String>> getFavoriteIds() async {
    final rows = await query(
      'SELECT recipe_id::text FROM favorites WHERE user_id = \$1',
      [kUserId],
    );
    return rows.map((r) => r['recipe_id'] as String).toList();
  }

  // ── COOKED RECIPES ─────────────────────────────────────────────────────────

  Future<void> markCooked(Meal meal) async {
    await upsertRecipe(meal);
    await execute(
      'INSERT INTO cooked_recipes (user_id, recipe_id) VALUES (\$1, \$2)',
      [kUserId, meal.id],
    );
  }

  Future<int> getCookedCount() async {
    final rows = await query(
      'SELECT COUNT(*)::int AS count FROM cooked_recipes WHERE user_id = \$1',
      [kUserId],
    );
    return rows.firstOrNull?['count'] as int? ?? 0;
  }

  // ── MEAL PLANS ─────────────────────────────────────────────────────────────

  Future<void> saveMealPlanSlot(
      String date, String mealType, Meal meal) async {
    await upsertRecipe(meal);
    await execute(
      'DELETE FROM meal_plans WHERE user_id=\$1 AND date=\$2 AND meal_type=\$3',
      [kUserId, date, mealType],
    );
    await execute(
      'INSERT INTO meal_plans (user_id, date, meal_type, recipe_id) VALUES (\$1, \$2, \$3, \$4)',
      [kUserId, date, mealType, meal.id],
    );
  }

  Future<List<Map<String, dynamic>>> getMealPlan(
      String startDate, String endDate) async {
    return query('''
      SELECT mp.date::text, mp.meal_type, r.id::text AS recipe_id,
             r.title, r.image_url, r.calories, r.duration
      FROM meal_plans mp
      LEFT JOIN recipes r ON r.id = mp.recipe_id
      WHERE mp.user_id = \$1
        AND mp.date BETWEEN \$2::date AND \$3::date
      ORDER BY mp.date, mp.meal_type
    ''', [kUserId, startDate, endDate]);
  }
}
