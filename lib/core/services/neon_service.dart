import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import '../../features/meals/models/meal.dart';
import '../config/app_secrets.dart';

class NeonService {
  static const _host = 'ep-dawn-night-abd29yl2-pooler.eu-west-2.aws.neon.tech';
  static const _user = 'neondb_owner';

  static String? _currentUserId;
  static String get kUserId =>
      _currentUserId ?? '00000000-0000-0000-0000-000000000001';
  static void setCurrentUser(String id) => _currentUserId = id;
  static void clearCurrentUser() => _currentUserId = null;

  /// Neon `/sql` attend cet en-tête (pas Basic Auth). Cf. @neondatabase/serverless.
  static String get _connectionString {
    final pw = Uri.encodeComponent(kNeonPassword);
    return 'postgresql://$_user:$pw@$_host/neondb?sslmode=require';
  }

  /// Web : même origine que l’app (nginx proxy → Neon). Mobile/desktop : Neon direct.
  Uri get _sqlUri =>
      kIsWeb ? Uri.base.resolve('/api/neon/sql') : Uri.https(_host, '/sql');

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic> params = const [],
  ]) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (!kIsWeb) {
      headers['Neon-Connection-String'] = _connectionString;
    }

    final resp = await http.post(
      _sqlUri,
      headers: headers,
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
    await execute('DELETE FROM user_goals WHERE user_id = \$1', [kUserId]);
    if (goal != null) {
      await execute(
        'INSERT INTO user_goals (user_id, goal) VALUES (\$1, \$2)',
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
      query('SELECT goal FROM user_goals WHERE user_id = \$1', [kUserId]),
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

  String _difficultyToFr(String? d) {
    final v = d ?? 'facile';
    return switch (v) {
      'intermediaire' => 'intermédiaire',
      _ => v,
    };
  }

  /// Recettes liées à l’utilisateur (favoris, planning, historique « cuisiné »).
  Future<List<Meal>> loadUserRecipesCatalog() async {
    final idRows = await query(
      r'''
      SELECT DISTINCT recipe_id::text AS id FROM (
        SELECT recipe_id FROM favorites WHERE user_id = $1::uuid
        UNION
        SELECT recipe_id FROM meal_plans
        WHERE user_id = $1::uuid AND recipe_id IS NOT NULL
        UNION
        SELECT recipe_id FROM cooked_recipes WHERE user_id = $1::uuid
      ) s
      ''',
      [kUserId],
    );
    final ids = idRows
        .map((r) => r['id'] as String)
        .where((s) => s.isNotEmpty)
        .toList();
    if (ids.isEmpty) return [];

    final favSet = (await getFavoriteIds()).toSet();
    final meals = <Meal>[];
    for (final id in ids) {
      final m = await _loadRecipeMeal(id, favSet.contains(id));
      if (m != null) meals.add(m);
    }
    meals.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return meals;
  }

  Future<Meal?> _loadRecipeMeal(String id, bool isFavorite) async {
    final rRows = await query(
      r'''
      SELECT id::text, title, image_url, duration, calories, difficulty, type, type_label,
             emoji, color, locked
      FROM recipes WHERE id = $1::uuid
      ''',
      [id],
    );
    if (rRows.isEmpty) return null;
    final r = rRows.first;

    final stepRows = await query(
      r'''
      SELECT instruction FROM recipe_steps
      WHERE recipe_id = $1::uuid ORDER BY step_order
      ''',
      [id],
    );
    final steps = stepRows
        .map((x) => x['instruction'] as String)
        .where((s) => s.isNotEmpty)
        .toList();

    final ingRows = await query(
      r'''
      SELECT i.name, ri.quantity, ri.unit
      FROM recipe_ingredients ri
      JOIN ingredients i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = $1::uuid
      ''',
      [id],
    );
    final ingredients = ingRows.map((row) {
      final name = row['name'] as String? ?? '';
      final q = row['quantity'];
      final u = row['unit'] as String? ?? '';
      String qtyStr;
      if (q == null) {
        qtyStr = u;
      } else {
        final qs = q is num ? _trimDecimal(q.toDouble()) : q.toString();
        qtyStr = u.isEmpty ? qs : '$qs $u';
      }
      return Ingredient(name: name, qty: qtyStr.trim(), photo: '');
    }).toList();

    final duration = (r['duration'] as num?)?.toInt() ?? 0;

    return Meal(
      id: r['id'] as String,
      title: r['title'] as String? ?? '',
      photo: r['image_url'] as String? ?? '',
      kcal: (r['calories'] as num?)?.toInt() ?? 0,
      protein: 'moyen',
      difficulty: _difficultyToFr(r['difficulty'] as String?),
      time: duration > 0 ? '$duration min' : '—',
      locked: r['locked'] as bool? ?? false,
      type: r['type'] as String? ?? 'simple',
      typeLabel: r['type_label'] as String? ?? '',
      emoji: r['emoji'] as String? ?? '🍽️',
      color: r['color'] as String? ?? '#82D28C',
      ingredients: ingredients,
      steps: steps.isEmpty
          ? const ['Aucune étape détaillée en base pour cette recette.']
          : steps,
      isFavorite: isFavorite,
    );
  }

  String _trimDecimal(double x) {
    if (x == x.roundToDouble()) return x.round().toString();
    return x.toString();
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

  // ── SYNC APP STATE (frigo, planning, streak connexion) ─────────────────────

  Future<void> ensureUserSyncSchema() async {
    await ensureRelationalSchema();
    try {
      await execute(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS fridge_ingredients_json TEXT',
      );
      await execute(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS plan_selections_json TEXT',
      );
      await execute(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_date DATE',
      );
      await execute(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS login_streak INTEGER DEFAULT 0',
      );
      await execute(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS scan_meals_json TEXT',
      );
      await execute(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS cooking_level TEXT',
      );
    } catch (e) {
      debugPrint('ensureUserSyncSchema columns: $e');
    }
  }

  /// Crée les tables attendues par l’app si elles n’existent pas (Neon par défaut ≠ schéma Fridge).
  Future<void> ensureRelationalSchema() async {
    Future<void> run(String sql) async {
      try {
        await execute(sql);
      } catch (e) {
        debugPrint('Neon ensureRelationalSchema: $e');
      }
    }

    await run('''
CREATE TABLE IF NOT EXISTS nutrition_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  calories INT NOT NULL DEFAULT 2000,
  proteins INT NOT NULL DEFAULT 150,
  carbs INT NOT NULL DEFAULT 200,
  fats INT NOT NULL DEFAULT 65
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_goals (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  goal TEXT
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS allergies (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS diets (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_allergies (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  allergy_id INT NOT NULL REFERENCES allergies(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, allergy_id)
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_diets (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  diet_id INT NOT NULL REFERENCES diets(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, diet_id)
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_notifications (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  notif_expiry BOOLEAN NOT NULL DEFAULT TRUE,
  notif_suggestion BOOLEAN NOT NULL DEFAULT TRUE,
  notif_fridge BOOLEAN NOT NULL DEFAULT TRUE
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  image_url TEXT,
  duration INT NOT NULL DEFAULT 0,
  calories INT NOT NULL DEFAULT 0,
  difficulty TEXT,
  type TEXT,
  type_label TEXT,
  emoji TEXT,
  color TEXT,
  locked BOOLEAN NOT NULL DEFAULT FALSE
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS ingredients (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS recipe_steps (
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  step_order INT NOT NULL,
  instruction TEXT NOT NULL,
  PRIMARY KEY (recipe_id, step_order)
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS recipe_ingredients (
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  ingredient_id INT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  quantity DOUBLE PRECISION,
  unit TEXT,
  PRIMARY KEY (recipe_id, ingredient_id)
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS favorites (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, recipe_id)
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS cooked_recipes (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, recipe_id)
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS meal_plans (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  meal_type TEXT NOT NULL,
  recipe_id UUID REFERENCES recipes(id) ON DELETE SET NULL,
  PRIMARY KEY (user_id, date, meal_type)
)
''');
  }

  /// Recettes issues des scans (JSON), fusionnées par id à chaque nouveau scan.
  Future<List<Meal>> loadScanMeals() async {
    final rows = await query(
      'SELECT scan_meals_json FROM users WHERE id = \$1',
      [kUserId],
    );
    if (rows.isEmpty) return [];
    final raw = rows.first['scan_meals_json'];
    if (raw == null) return [];
    final str = raw.toString();
    if (str.isEmpty) return [];
    final decoded = jsonDecode(str);
    if (decoded is! List) return [];
    return decoded
        .map(
          (e) => Meal.fromJson(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
          ),
        )
        .toList();
  }

  Future<void> mergeAndSaveScanMeals(List<Meal> newMeals) async {
    final existing = await loadScanMeals();
    final map = {for (final m in existing) m.id: m};
    for (final m in newMeals) {
      map[m.id] = m;
    }
    final encoded =
        jsonEncode(map.values.map((m) => m.toJson()).toList(growable: false));
    await execute(
      'UPDATE users SET scan_meals_json = \$1 WHERE id = \$2',
      [encoded, kUserId],
    );
  }

  Future<void> saveFridgeIngredients(List<String> items) async {
    await execute(
      'UPDATE users SET fridge_ingredients_json = \$1 WHERE id = \$2',
      [jsonEncode(items), kUserId],
    );
  }

  Future<List<String>> loadFridgeIngredients() async {
    final rows = await query(
      'SELECT fridge_ingredients_json FROM users WHERE id = \$1',
      [kUserId],
    );
    if (rows.isEmpty) return [];
    final raw = rows.first['fridge_ingredients_json'];
    if (raw == null) return [];
    final decoded = jsonDecode(raw as String);
    if (decoded is! List) return [];
    return decoded.map((e) => e.toString()).toList();
  }

  Future<void> savePlanSelections(Map<String, Meal> selections) async {
    final payload = jsonEncode(
      selections.map((k, v) => MapEntry(k, v.toJson())),
    );
    await execute(
      'UPDATE users SET plan_selections_json = \$1 WHERE id = \$2',
      [payload, kUserId],
    );
  }

  Future<Map<String, Meal>?> loadPlanSelections() async {
    final rows = await query(
      'SELECT plan_selections_json FROM users WHERE id = \$1',
      [kUserId],
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['plan_selections_json'];
    if (raw == null || (raw is String && raw.isEmpty)) return null;
    final str = raw as String;
    final decoded = jsonDecode(str) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, Meal.fromJson(v as Map<String, dynamic>)),
    );
  }

  static String _isoLocal(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Met à jour la série de jours consécutifs avec ouverture app (date locale).
  /// Retourne le streak actuel après mise à jour.
  Future<int> recordDailyLoginAndGetStreak() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayIso = _isoLocal(todayDate);

    final rows = await query(
      '''
      SELECT last_login_date::text, COALESCE(login_streak, 0) AS login_streak
      FROM users WHERE id = \$1
      ''',
      [kUserId],
    );
    if (rows.isEmpty) return 0;

    final lastStr = rows.first['last_login_date'] as String?;
    final sr = rows.first['login_streak'];
    final currentStreak = sr is int ? sr : (sr as num?)?.toInt() ?? 0;

    if (lastStr == null || lastStr.isEmpty) {
      await execute(
        '''
        UPDATE users SET last_login_date = \$1::date, login_streak = 1
        WHERE id = \$2
        ''',
        [todayIso, kUserId],
      );
      return 1;
    }

    DateTime lastDate;
    try {
      lastDate = DateTime.parse(lastStr.split(' ').first.trim());
    } catch (_) {
      final streakReset = 1;
      await execute(
        '''
        UPDATE users SET last_login_date = \$1::date, login_streak = \$2
        WHERE id = \$3
        ''',
        [todayIso, streakReset, kUserId],
      );
      return streakReset;
    }
    final lastLocal =
        DateTime(lastDate.year, lastDate.month, lastDate.day);

    if (lastLocal == todayDate) {
      return currentStreak;
    }

    final yesterday = todayDate.subtract(const Duration(days: 1));
    final newStreak = lastLocal == yesterday ? currentStreak + 1 : 1;

    await execute(
      '''
      UPDATE users SET last_login_date = \$1::date, login_streak = \$2
      WHERE id = \$3
      ''',
      [todayIso, newStreak, kUserId],
    );
    return newStreak;
  }
}
