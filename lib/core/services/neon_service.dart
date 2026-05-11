import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../features/meals/models/meal.dart';
import '../config/app_secrets.dart';
import '../utils/recipe_ids.dart';

class NeonService {
  static const _host = 'ep-dawn-night-abd29yl2-pooler.eu-west-2.aws.neon.tech';
  static const _user = 'neondb_owner';
  static const _uuid = Uuid();

  static String? _currentUserId;
  static String get kUserId {
    final raw = _currentUserId ?? '00000000-0000-0000-0000-000000000001';
    if (Uuid.isValidUUID(fromString: raw)) return raw;
    // Compat sessions anciennes avec id non-UUID.
    return _uuid.v5(Namespace.url.value, 'fridge-user:$raw');
  }
  static void setCurrentUser(String id) => _currentUserId = id;
  static void clearCurrentUser() => _currentUserId = null;

  Future<void> _ensureUserRowExists() async {
    final uid = kUserId;
    final fallbackEmail = 'user-$uid@fridge.local';
    await execute(
      '''
      INSERT INTO users (id, name, email)
      VALUES (\$1::uuid, \$2, \$3)
      ON CONFLICT (id) DO NOTHING
      ''',
      [uid, 'Utilisateur', fallbackEmail],
    );
  }

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
    await _ensureUserRowExists();
    await execute('''
      INSERT INTO user_cooking_levels (user_id, cooking_level)
      VALUES (\$1::uuid, \$2)
      ON CONFLICT (user_id) DO UPDATE SET
        cooking_level = EXCLUDED.cooking_level
    ''', [kUserId, level]);
    // Compat: garde aussi la colonne historique sur users.
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

  /// Table `goals` : id, user_id, goal (visible dans Neon / Supabase — pas user_goals).
  Future<void> saveGoal(String? goal) async {
    await execute('DELETE FROM goals WHERE user_id = \$1', [kUserId]);
    if (goal != null) {
      await execute(
        '''
        INSERT INTO goals (id, user_id, goal)
        VALUES (\$1::uuid, \$2::uuid, \$3)
        ''',
        [_uuid.v4(), kUserId, goal],
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

  // ── KITCHEN EQUIPMENTS ─────────────────────────────────────────────────────

  Future<void> saveKitchenEquipments(List<String> names) async {
    await execute(
      'DELETE FROM user_kitchen_equipments WHERE user_id = \$1',
      [kUserId],
    );
    for (final name in names) {
      await execute(
        'INSERT INTO kitchen_equipments (name) VALUES (\$1) ON CONFLICT (name) DO NOTHING',
        [name],
      );
      await execute('''
        INSERT INTO user_kitchen_equipments (user_id, equipment_id)
        SELECT \$1, id FROM kitchen_equipments WHERE name = \$2
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

  // ── THEME PREFERENCE ────────────────────────────────────────────────────────

  Future<void> saveThemePreference(String theme) async {
    await _ensureUserRowExists();
    await execute(
      '''
      INSERT INTO user_theme_preferences (user_id, theme_preference, updated_at)
      VALUES (\$1::uuid, \$2, NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        theme_preference = EXCLUDED.theme_preference,
        updated_at = NOW()
      ''',
      [kUserId, theme],
    );
  }

  Future<String?> loadThemePreference() async {
    final rows = await query(
      '''
      SELECT theme_preference
      FROM user_theme_preferences
      WHERE user_id = \$1::uuid
      LIMIT 1
      ''',
      [kUserId],
    );
    if (rows.isEmpty) return null;
    return rows.first['theme_preference'] as String?;
  }

  // ── AI TONE (Coach / Chef / Ami) ───────────────────────────────────────────

  Future<void> saveAiTonePreference(String aiTone) async {
    await _ensureUserRowExists();
    await execute(
      '''
      INSERT INTO user_ai_tone_preferences (user_id, ai_tone, updated_at)
      VALUES (\$1::uuid, \$2, NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        ai_tone = EXCLUDED.ai_tone,
        updated_at = NOW()
      ''',
      [kUserId, aiTone],
    );
  }

  Future<String?> loadAiTonePreference() async {
    final rows = await query(
      '''
      SELECT ai_tone
      FROM user_ai_tone_preferences
      WHERE user_id = \$1::uuid
      LIMIT 1
      ''',
      [kUserId],
    );
    if (rows.isEmpty) return null;
    return rows.first['ai_tone'] as String?;
  }

  Future<void> upsertPushToken({
    required String token,
    required String platform,
  }) async {
    await _ensureUserRowExists();
    await execute(
      '''
      INSERT INTO user_push_tokens (user_id, token, platform, updated_at, is_active)
      VALUES (\$1::uuid, \$2, \$3, NOW(), TRUE)
      ON CONFLICT (token) DO UPDATE SET
        user_id = EXCLUDED.user_id,
        platform = EXCLUDED.platform,
        updated_at = NOW(),
        is_active = TRUE
      ''',
      [kUserId, token, platform],
    );
  }

  Future<void> deactivatePushToken(String token) async {
    await execute(
      '''
      UPDATE user_push_tokens
      SET is_active = FALSE, updated_at = NOW()
      WHERE token = \$1
      ''',
      [token],
    );
  }

  // ── USER PHOTOS ────────────────────────────────────────────────────────────

  Future<void> saveUserPhotoBytes(Uint8List bytes) async {
    await _ensureUserRowExists();
    await execute(
      '''
      INSERT INTO user_photos (id, user_id, photo_base64)
      VALUES (\$1::uuid, \$2::uuid, \$3)
      ''',
      [_uuid.v4(), kUserId, base64Encode(bytes)],
    );
  }

  Future<List<Map<String, dynamic>>> loadUserPhotos() async {
    return query(
      '''
      SELECT id::text, photo_base64, created_at::text
      FROM user_photos
      WHERE user_id = \$1::uuid
      ORDER BY created_at DESC
      ''',
      [kUserId],
    );
  }

  Future<void> deleteUserPhoto(String photoId) async {
    await execute(
      'DELETE FROM user_photos WHERE id = \$1::uuid AND user_id = \$2::uuid',
      [photoId, kUserId],
    );
  }

  // ── LOAD FULL PROFILE ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadProfile() async {
    final results = await Future.wait([
      query('''
        SELECT u.name, u.email, COALESCE(ucl.cooking_level, u.cooking_level) AS cooking_level
        FROM users u
        LEFT JOIN user_cooking_levels ucl ON ucl.user_id = u.id
        WHERE u.id = \$1::uuid
      ''', [kUserId]),
      query(
          'SELECT calories, proteins, carbs, fats FROM nutrition_profiles WHERE user_id = \$1',
          [kUserId]),
      query(
        'SELECT goal FROM goals WHERE user_id = \$1::uuid LIMIT 1',
        [kUserId],
      ),
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
      query('''
        SELECT ke.name
        FROM kitchen_equipments ke
        JOIN user_kitchen_equipments uke ON uke.equipment_id = ke.id
        WHERE uke.user_id = \$1
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
      'kitchenEquipments': results[5].map((r) => r['name'] as String).toList(),
      'notifications': results[6].firstOrNull,
    };
  }

  // ── RECIPES ────────────────────────────────────────────────────────────────

  Future<void> upsertRecipe(Meal meal) async {
    final rid = normalizeRecipeId(meal.id);
    final duration =
        int.tryParse(meal.time.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final prep = meal.prepTimeMin;
    final rest = meal.restTimeMin;
    final cook = meal.cookTimeMin > 0 ? meal.cookTimeMin : duration;
    final difficulty =
        meal.difficulty.replaceAll('é', 'e').replaceAll('è', 'e');

    await execute('''
      INSERT INTO recipes (
        id, title, image_url, duration, calories,
        difficulty, type, type_label, emoji, color, locked,
        prep_time_min, rest_time_min, cook_time_min,
        protein_g, carbs_g, fats_g
      ) VALUES (\$1,\$2,\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14,\$15,\$16,\$17)
      ON CONFLICT (id) DO UPDATE SET
        title         = EXCLUDED.title,
        image_url     = EXCLUDED.image_url,
        prep_time_min = EXCLUDED.prep_time_min,
        rest_time_min = EXCLUDED.rest_time_min,
        cook_time_min = EXCLUDED.cook_time_min,
        protein_g     = EXCLUDED.protein_g,
        carbs_g       = EXCLUDED.carbs_g,
        fats_g        = EXCLUDED.fats_g
    ''', [
      rid,
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
      prep,
      rest,
      cook,
      meal.proteinG,
      meal.carbsG,
      meal.fatsG,
    ]);

    await execute(
        'DELETE FROM recipe_steps WHERE recipe_id = \$1', [rid]);
    for (int i = 0; i < meal.steps.length; i++) {
      await execute(
        'INSERT INTO recipe_steps (recipe_id, step_order, instruction) VALUES (\$1, \$2, \$3)',
        [rid, i + 1, meal.steps[i]],
      );
    }

    await execute(
        'DELETE FROM recipe_ingredients WHERE recipe_id = \$1', [rid]);
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
      ''', [rid, ing.name, qty, unit]);
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

  /// Récupère des exemples de recettes depuis la DB pour guider l'IA sur le style,
  /// la structure et le niveau de détail. La table principale varie selon l'objectif :
  /// - 'muscleGain' → priorité recipes_v2 (sport / protéiné)
  /// - 'weightLoss' → priorité recipes_v3 (minceur / léger)
  /// - autres → priorité recipes_marmiton (cuisine générale diversifiée)
  Future<List<Map<String, dynamic>>> fetchStructureExamples({
    String? goal,
    int perSource = 3,
  }) async {
    final results = <Map<String, dynamic>>[];

    Future<void> tryFetch(String table, String defaultCategory, int limit) async {
      try {
        final rows = await query(
          '''
          SELECT DISTINCT ON (COALESCE(category, title))
            title,
            COALESCE(category, '$defaultCategory') AS category,
            ingredients_json::text AS ingredients_text,
            steps_json::text       AS steps_text,
            COALESCE(calories, 0)  AS calories,
            COALESCE(difficulty, 'facile') AS difficulty,
            COALESCE(duration, 30) AS duration
          FROM $table
          WHERE steps_json IS NOT NULL AND ingredients_json IS NOT NULL
          ORDER BY COALESCE(category, title), RANDOM()
          LIMIT \$1
          ''',
          [limit],
        );
        results.addAll(rows);
      } catch (_) {
        // Fallback sans colonne category
        try {
          final rows = await query(
            '''
            SELECT
              title,
              '$defaultCategory' AS category,
              ingredients_json::text AS ingredients_text,
              steps_json::text       AS steps_text,
              COALESCE(calories, 0)  AS calories,
              COALESCE(difficulty, 'facile') AS difficulty,
              COALESCE(duration, 30) AS duration
            FROM $table
            WHERE steps_json IS NOT NULL AND ingredients_json IS NOT NULL
            ORDER BY RANDOM()
            LIMIT \$1
            ''',
            [limit],
          );
          results.addAll(rows);
        } catch (_) {}
      }
    }

    if (goal == 'muscleGain') {
      // Sport en priorité, complété par marmiton pour la diversité
      await tryFetch('recipes_v2', 'sport', perSource * 3);
      await tryFetch('recipes_marmiton', 'plat principal', perSource);
    } else if (goal == 'weightLoss') {
      // Minceur en priorité, complété par marmiton
      await tryFetch('recipes_v3', 'minceur', perSource * 3);
      await tryFetch('recipes_marmiton', 'plat principal', perSource);
    } else {
      // Cuisine générale : marmiton en base + un peu de v2 et v3 pour la diversité
      await tryFetch('recipes_marmiton', 'plat principal', perSource * 3);
      await tryFetch('recipes_v2', 'sport', perSource);
      await tryFetch('recipes_v3', 'minceur', perSource);
    }

    return results;
  }

  Future<List<Meal>> loadMarmitonRecipes({int limit = 20}) async {
    final rows = await query(
      '''
      SELECT row_to_json(t) AS row
      FROM (
        SELECT * FROM recipes_marmiton
        ORDER BY id
        LIMIT \$1
      ) t
      ''',
      [limit],
    );

    final out = <Meal>[];
    for (var i = 0; i < rows.length; i++) {
      final raw = rows[i]['row'];
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw as Map);

      String pickString(List<String> keys, {String fallback = ''}) {
        for (final k in keys) {
          final v = map[k];
          if (v != null && v.toString().trim().isNotEmpty) return v.toString();
        }
        return fallback;
      }

      int pickInt(List<String> keys, {int fallback = 0}) {
        for (final k in keys) {
          final v = map[k];
          if (v is int) return v;
          if (v is num) return v.toInt();
          if (v is String) {
            final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
            if (parsed != null) return parsed;
          }
        }
        return fallback;
      }

      List<Ingredient> pickIngredients() {
        final dynamic rawIngredients =
            map['ingredients_json'] ?? map['ingredients'];
        if (rawIngredients is List) {
          final result = <Ingredient>[];
          for (final e in rawIngredients) {
            if (e is Map) {
              final m = Map<String, dynamic>.from(e as Map);
              result.add(Ingredient(
                name: (m['name'] ?? m['ingredient'] ?? '').toString(),
                qty: (m['qty'] ?? m['quantity'] ?? '').toString(),
                photo: (m['photo'] ?? m['image'] ?? '').toString(),
              ));
            } else {
              final str = e.toString().trim();
              if (str.contains('|')) {
                result.addAll(
                  str.split(RegExp(r'\|+')).map((s) => s.trim()).where((s) => s.isNotEmpty).map((s) => Ingredient(name: s, qty: '', photo: '')),
                );
              } else if (str.isNotEmpty) {
                result.add(Ingredient(name: str, qty: '', photo: ''));
              }
            }
          }
          return result;
        }
        if (rawIngredients is String && rawIngredients.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawIngredients);
            if (decoded is List) {
              return decoded.map((e) {
                if (e is Map) {
                  final m = Map<String, dynamic>.from(e as Map);
                  return Ingredient(
                    name: (m['name'] ?? m['ingredient'] ?? '').toString(),
                    qty: (m['qty'] ?? m['quantity'] ?? '').toString(),
                    photo: (m['photo'] ?? m['image'] ?? '').toString(),
                  );
                }
                return Ingredient(name: e.toString(), qty: '', photo: '');
              }).toList();
            }
          } catch (_) {}
          return rawIngredients
              .split(RegExp(r'[,|]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((e) => Ingredient(name: e, qty: '', photo: ''))
              .toList();
        }
        return const [];
      }

      List<String> pickSteps() {
        final dynamic rawSteps =
            map['steps_json'] ?? map['steps'] ?? map['instructions'];
        if (rawSteps is List) {
          final result = <String>[];
          for (final e in rawSteps) {
            final str = e.toString().trim();
            if (str.contains('||')) {
              result.addAll(str.split('||').map((s) => s.trim()).where((s) => s.isNotEmpty));
            } else if (str.contains('|')) {
              result.addAll(str.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty));
            } else if (str.isNotEmpty) {
              result.add(str);
            }
          }
          return result;
        }
        if (rawSteps is String && rawSteps.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawSteps);
            if (decoded is List) {
              return decoded
                  .map((e) => e.toString())
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          } catch (_) {}
          return rawSteps
              .split(RegExp(r'[\n\r|]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        return const [];
      }

      final title = pickString(['title', 'name', 'recipe_name'], fallback: 'Recette');
      final duration = pickInt(
          ['duration', 'duration_min', 'time', 'time_min', 'ready_in_minutes'],
          fallback: 20);
      final kcal = pickInt(['calories', 'kcal', 'energy'], fallback: 0);
      final difficulty = pickString(['difficulty', 'niveau'], fallback: 'facile');
      final type = pickString(['type'], fallback: i == 1 ? 'balanced' : 'simple');
      final typeLabel = pickString(['type_label'],
          fallback: type == 'balanced' ? 'Équilibré' : 'Simple');
      final emoji = pickString(['emoji'], fallback: i == 0 ? '🍝' : '🍽️');
      final color = pickString(['color'], fallback: '#82D28C');
      final photo =
          pickString(['image_url', 'image', 'photo', 'thumbnail'], fallback: '');
      final locked = (map['locked'] as bool?) ?? false;
      final ridRaw =
          pickString(['id', 'recipe_id', 'uuid'], fallback: '$title-$i');
      final rid = normalizeRecipeId(ridRaw);
      final ingredients = pickIngredients();
      final steps = pickSteps();

      out.add(
        Meal(
          id: rid,
          type: type,
          typeLabel: typeLabel,
          emoji: emoji,
          title: title,
          kcal: kcal,
          protein: 'moyen',
          difficulty: _difficultyToFr(difficulty),
          time: '$duration min',
          locked: locked,
          photo: photo,
          ingredients: ingredients,
          steps: steps.isEmpty
              ? const ['Aucune étape détaillée en base pour cette recette.']
              : steps,
          color: color,
          prepTimeMin: duration,
          cookTimeMin: duration,
        ),
      );
    }
    return out;
  }

  Future<List<Meal>> loadRecipesV2({String? category, int limit = 10}) async {
    final rows = await query(
      category != null
          ? '''
            SELECT row_to_json(t) AS row
            FROM (
              SELECT * FROM recipes_v2
              WHERE category ILIKE \$2
              ORDER BY id
              LIMIT \$1
            ) t
            '''
          : '''
            SELECT row_to_json(t) AS row
            FROM (
              SELECT * FROM recipes_v2
              ORDER BY id
              LIMIT \$1
            ) t
            ''',
      category != null ? [limit, category] : [limit],
    );

    final out = <Meal>[];
    for (var i = 0; i < rows.length; i++) {
      final raw = rows[i]['row'];
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw as Map);

      String pickString(List<String> keys, {String fallback = ''}) {
        for (final k in keys) {
          final v = map[k];
          if (v != null && v.toString().trim().isNotEmpty) return v.toString();
        }
        return fallback;
      }

      int pickInt(List<String> keys, {int fallback = 0}) {
        for (final k in keys) {
          final v = map[k];
          if (v is int) return v;
          if (v is num) return v.toInt();
          if (v is String) {
            final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
            if (parsed != null) return parsed;
          }
        }
        return fallback;
      }

      List<Ingredient> pickIngredients() {
        final dynamic rawIngredients =
            map['ingredients_json'] ?? map['ingredients'];
        if (rawIngredients is List) {
          final result = <Ingredient>[];
          for (final e in rawIngredients) {
            if (e is Map) {
              final m = Map<String, dynamic>.from(e as Map);
              result.add(Ingredient(
                name: (m['name'] ?? m['ingredient'] ?? '').toString(),
                qty: (m['qty'] ?? m['quantity'] ?? '').toString(),
                photo: (m['photo'] ?? m['image'] ?? '').toString(),
              ));
            } else {
              final str = e.toString().trim();
              if (str.contains('|')) {
                result.addAll(
                  str.split(RegExp(r'\|+')).map((s) => s.trim()).where((s) => s.isNotEmpty).map((s) => Ingredient(name: s, qty: '', photo: '')),
                );
              } else if (str.isNotEmpty) {
                result.add(Ingredient(name: str, qty: '', photo: ''));
              }
            }
          }
          return result;
        }
        if (rawIngredients is String && rawIngredients.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawIngredients);
            if (decoded is List) {
              return decoded.map((e) {
                if (e is Map) {
                  final m = Map<String, dynamic>.from(e as Map);
                  return Ingredient(
                    name: (m['name'] ?? m['ingredient'] ?? '').toString(),
                    qty: (m['qty'] ?? m['quantity'] ?? '').toString(),
                    photo: (m['photo'] ?? m['image'] ?? '').toString(),
                  );
                }
                return Ingredient(name: e.toString(), qty: '', photo: '');
              }).toList();
            }
          } catch (_) {}
          return rawIngredients
              .split(RegExp(r'[,|]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((e) => Ingredient(name: e, qty: '', photo: ''))
              .toList();
        }
        return const [];
      }

      List<String> splitSentences(String str) {
        if (str.contains('||')) return str.split('||').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (str.contains('|')) return str.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        if (str.contains('\n')) return str.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        final parts = str.split(RegExp(r'\.\s+(?=[A-ZÀ-Üa-zà-ü0-9])'));
        if (parts.length > 1) {
          return parts.map((s) {
            s = s.trim();
            if (s.isNotEmpty && !s.endsWith('.') && !s.endsWith('!') && !s.endsWith('?')) s = '$s.';
            return s;
          }).where((s) => s.isNotEmpty).toList();
        }
        return str.isNotEmpty ? [str] : [];
      }

      List<String> pickSteps() {
        final dynamic rawSteps =
            map['steps_json'] ?? map['steps'] ?? map['instructions'];
        if (rawSteps is List) {
          final result = <String>[];
          for (final e in rawSteps) {
            result.addAll(splitSentences(e.toString().trim()));
          }
          return result;
        }
        if (rawSteps is String && rawSteps.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawSteps);
            if (decoded is List) {
              final result = <String>[];
              for (final e in decoded) {
                result.addAll(splitSentences(e.toString().trim()));
              }
              return result;
            }
          } catch (_) {}
          return splitSentences(rawSteps.trim());
        }
        return const [];
      }

      final title = pickString(['title', 'name', 'recipe_name'], fallback: 'Recette');
      final duration = pickInt(
          ['duration', 'duration_min', 'time', 'time_min', 'ready_in_minutes'],
          fallback: 20);
      final kcal = pickInt(['calories', 'kcal', 'energy'], fallback: 0);
      final difficulty = pickString(['difficulty', 'niveau'], fallback: 'facile');
      final type = pickString(['type'], fallback: i == 1 ? 'balanced' : 'simple');
      final typeLabel = pickString(['type_label'],
          fallback: type == 'balanced' ? 'Équilibré' : 'Simple');
      final emoji = pickString(['emoji'], fallback: '🏋️');
      final color = pickString(['color'], fallback: '#82D28C');
      final rawPhoto = pickString(['image_url', 'image', 'photo', 'thumbnail'], fallback: '');
      final photo = rawPhoto.isNotEmpty ? rawPhoto : _sportImageFallback(title);
      final locked = (map['locked'] as bool?) ?? false;
      final ridRaw = pickString(['id', 'recipe_id', 'uuid'], fallback: '$title-$i');
      final rid = normalizeRecipeId(ridRaw);
      final ingredients = pickIngredients();
      final steps = pickSteps();

      out.add(
        Meal(
          id: rid,
          type: type,
          typeLabel: typeLabel,
          emoji: emoji,
          title: title,
          kcal: kcal,
          protein: 'moyen',
          difficulty: _difficultyToFr(difficulty),
          time: '$duration min',
          locked: locked,
          photo: photo,
          ingredients: ingredients,
          steps: steps.isEmpty
              ? const ['Aucune étape détaillée en base pour cette recette.']
              : steps,
          color: color,
          prepTimeMin: duration,
          cookTimeMin: duration,
        ),
      );
    }
    return out;
  }

  Future<List<Meal>> loadRecipesV3({String? category, int limit = 10}) async {
    final rows = await query(
      category != null
          ? '''
            SELECT row_to_json(t) AS row
            FROM (
              SELECT * FROM recipes_v3
              WHERE category ILIKE \$2
              ORDER BY id
              LIMIT \$1
            ) t
            '''
          : '''
            SELECT row_to_json(t) AS row
            FROM (
              SELECT * FROM recipes_v3
              ORDER BY id
              LIMIT \$1
            ) t
            ''',
      category != null ? [limit, category] : [limit],
    );

    final out = <Meal>[];
    for (var i = 0; i < rows.length; i++) {
      final raw = rows[i]['row'];
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw as Map);

      String pickString(List<String> keys, {String fallback = ''}) {
        for (final k in keys) {
          final v = map[k];
          if (v != null && v.toString().trim().isNotEmpty) return v.toString();
        }
        return fallback;
      }

      int pickInt(List<String> keys, {int fallback = 0}) {
        for (final k in keys) {
          final v = map[k];
          if (v is int) return v;
          if (v is num) return v.toInt();
          if (v is String) {
            final parsed = int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
            if (parsed != null) return parsed;
          }
        }
        return fallback;
      }

      List<Ingredient> pickIngredients() {
        final dynamic rawIngredients =
            map['ingredients_json'] ?? map['ingredients'];
        if (rawIngredients is List) {
          final result = <Ingredient>[];
          for (final e in rawIngredients) {
            if (e is Map) {
              final m = Map<String, dynamic>.from(e as Map);
              result.add(Ingredient(
                name: (m['name'] ?? m['ingredient'] ?? '').toString(),
                qty: (m['qty'] ?? m['quantity'] ?? '').toString(),
                photo: (m['photo'] ?? m['image'] ?? '').toString(),
              ));
            } else {
              final str = e.toString().trim();
              if (str.contains('|')) {
                result.addAll(
                  str
                      .split(RegExp(r'\|+'))
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .map((s) => Ingredient(name: s, qty: '', photo: '')),
                );
              } else if (str.isNotEmpty) {
                result.add(Ingredient(name: str, qty: '', photo: ''));
              }
            }
          }
          return result;
        }
        if (rawIngredients is String && rawIngredients.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawIngredients);
            if (decoded is List) {
              return decoded.map((e) {
                if (e is Map) {
                  final m = Map<String, dynamic>.from(e as Map);
                  return Ingredient(
                    name: (m['name'] ?? m['ingredient'] ?? '').toString(),
                    qty: (m['qty'] ?? m['quantity'] ?? '').toString(),
                    photo: (m['photo'] ?? m['image'] ?? '').toString(),
                  );
                }
                return Ingredient(name: e.toString(), qty: '', photo: '');
              }).toList();
            }
          } catch (_) {}
          return rawIngredients
              .split(RegExp(r'[,|]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map((e) => Ingredient(name: e, qty: '', photo: ''))
              .toList();
        }
        return const [];
      }

      List<String> splitSentences(String str) {
        if (str.contains('||')) {
          return str
              .split('||')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        if (str.contains('|')) {
          return str
              .split('|')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        if (str.contains('\n')) {
          return str
              .split('\n')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        final parts = str.split(RegExp(r'\.\s+(?=[A-ZÀ-Üa-zà-ü0-9])'));
        if (parts.length > 1) {
          return parts
              .map((s) {
                s = s.trim();
                if (s.isNotEmpty &&
                    !s.endsWith('.') &&
                    !s.endsWith('!') &&
                    !s.endsWith('?')) {
                  s = '$s.';
                }
                return s;
              })
              .where((s) => s.isNotEmpty)
              .toList();
        }
        return str.isNotEmpty ? [str] : [];
      }

      List<String> pickSteps() {
        final dynamic rawSteps =
            map['steps_json'] ?? map['steps'] ?? map['instructions'];
        if (rawSteps is List) {
          final result = <String>[];
          for (final e in rawSteps) {
            result.addAll(splitSentences(e.toString().trim()));
          }
          return result;
        }
        if (rawSteps is String && rawSteps.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawSteps);
            if (decoded is List) {
              final result = <String>[];
              for (final e in decoded) {
                result.addAll(splitSentences(e.toString().trim()));
              }
              return result;
            }
          } catch (_) {}
          return splitSentences(rawSteps.trim());
        }
        return const [];
      }

      final title =
          pickString(['title', 'name', 'recipe_name'], fallback: 'Recette');
      final duration = pickInt(
        ['duration', 'duration_min', 'time', 'time_min', 'ready_in_minutes'],
        fallback: 20,
      );
      final kcal = pickInt(['calories', 'kcal', 'energy'], fallback: 0);
      final difficulty =
          pickString(['difficulty', 'niveau'], fallback: 'facile');
      final type = pickString(['type'], fallback: i == 1 ? 'balanced' : 'simple');
      final typeLabel = pickString(
        ['type_label'],
        fallback: type == 'balanced' ? 'Équilibré' : 'Simple',
      );
      final emoji = pickString(['emoji'], fallback: '🥗');
      final color = pickString(['color'], fallback: '#82D28C');
      final rawPhoto = pickString(
        ['image_url', 'image', 'photo', 'thumbnail'],
        fallback: '',
      );
      final photo = rawPhoto.isNotEmpty ? rawPhoto : _sportImageFallback(title);
      final locked = (map['locked'] as bool?) ?? false;
      final ridRaw =
          pickString(['id', 'recipe_id', 'uuid'], fallback: '$title-$i');
      final rid = normalizeRecipeId(ridRaw);
      final ingredients = pickIngredients();
      final steps = pickSteps();

      out.add(
        Meal(
          id: rid,
          type: type,
          typeLabel: typeLabel,
          emoji: emoji,
          title: title,
          kcal: kcal,
          protein: 'moyen',
          difficulty: _difficultyToFr(difficulty),
          time: '$duration min',
          locked: locked,
          photo: photo,
          ingredients: ingredients,
          steps: steps.isEmpty
              ? const ['Aucune étape détaillée en base pour cette recette.']
              : steps,
          color: color,
          prepTimeMin: duration,
          cookTimeMin: duration,
        ),
      );
    }
    return out;
  }

  Future<Meal?> _loadRecipeMeal(String id, bool isFavorite) async {
    final rRows = await query(
      r'''
      SELECT id::text, title, image_url, duration, calories, difficulty, type, type_label,
             emoji, color, locked, prep_time_min, rest_time_min, cook_time_min
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
    final prepTimeMin = (r['prep_time_min'] as num?)?.toInt() ?? 0;
    final restTimeMin = (r['rest_time_min'] as num?)?.toInt() ?? 0;
    final cookTimeMin =
        ((r['cook_time_min'] as num?)?.toInt() ?? 0) > 0
            ? (r['cook_time_min'] as num).toInt()
            : duration;

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
      prepTimeMin: prepTimeMin,
      restTimeMin: restTimeMin,
      cookTimeMin: cookTimeMin,
    );
  }

  String _sportImageFallback(String title) {
    final t = title.toLowerCase();
    if (t.contains('shaker') || t.contains('whey') || t.contains('protéine') || t.contains('proteine')) {
      return 'https://images.unsplash.com/photo-1622979135225-d2ba269cf1ac?w=600';
    }
    if (t.contains('poulet') || t.contains('chicken')) {
      return 'https://images.unsplash.com/photo-1598103442097-8b74394b95c3?w=600';
    }
    if (t.contains('yaourt') || t.contains('yogurt') || t.contains('skyr')) {
      return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600';
    }
    if (t.contains('oeuf') || t.contains('omelette') || t.contains('œuf')) {
      return 'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=600';
    }
    if (t.contains('avoca')) {
      return 'https://images.unsplash.com/photo-1601039641847-7857b994d704?w=600';
    }
    if (t.contains('quinoa') || t.contains('bowl')) {
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600';
    }
    if (t.contains('fromage') || t.contains('cottage')) {
      return 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a318?w=600';
    }
    if (t.contains('flocon') || t.contains('porridge') || t.contains('avoine')) {
      return 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=600';
    }
    if (t.contains('thon') || t.contains('saumon') || t.contains('poisson')) {
      return 'https://images.unsplash.com/photo-1499028344343-cd173ffc68a9?w=600';
    }
    if (t.contains('steak') || t.contains('boeuf') || t.contains('bœuf') || t.contains('viande')) {
      return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=600';
    }
    if (t.contains('sandwich') || t.contains('pain')) {
      return 'https://images.unsplash.com/photo-1553909489-cd47e0ef937b?w=600';
    }
    if (t.contains('riz') || t.contains('rice')) {
      return 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=600';
    }
    if (t.contains('houmous') || t.contains('hummus') || t.contains('légume')) {
      return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600';
    }
    return 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=600';
  }

  String _trimDecimal(double x) {
    if (x == x.roundToDouble()) return x.round().toString();
    return x.toString();
  }

  // ── FAVORITES ──────────────────────────────────────────────────────────────

  Future<void> saveFavorite(Meal meal) async {
    await upsertRecipe(meal);
    final rid = normalizeRecipeId(meal.id);
    await execute('''
      INSERT INTO favorites (user_id, recipe_id)
      VALUES (\$1, \$2)
      ON CONFLICT DO NOTHING
    ''', [kUserId, rid]);
  }

  Future<void> removeFavorite(String mealId) async {
    await execute(
      'DELETE FROM favorites WHERE user_id = \$1 AND recipe_id = \$2',
      [kUserId, normalizeRecipeId(mealId)],
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
      [kUserId, normalizeRecipeId(meal.id)],
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
      [kUserId, date, mealType, normalizeRecipeId(meal.id)],
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
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS adapted_meals_json TEXT',
      );
      await execute(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS cooking_level TEXT',
      );
      await execute(
        'ALTER TABLE meal_plans ADD COLUMN IF NOT EXISTS slot_photo_base64 TEXT',
      );
      await execute(
        'ALTER TABLE meal_plans ADD COLUMN IF NOT EXISTS slot_analysis_json JSONB',
      );
      await execute(
        'ALTER TABLE recipes ADD COLUMN IF NOT EXISTS prep_time_min INTEGER DEFAULT 0',
      );
      await execute(
        'ALTER TABLE recipes ADD COLUMN IF NOT EXISTS rest_time_min INTEGER DEFAULT 0',
      );
      await execute(
        'ALTER TABLE recipes ADD COLUMN IF NOT EXISTS cook_time_min INTEGER DEFAULT 0',
      );
      await execute(
        'ALTER TABLE recipes ADD COLUMN IF NOT EXISTS protein_g INT DEFAULT 0',
      );
      await execute(
        'ALTER TABLE recipes ADD COLUMN IF NOT EXISTS carbs_g INT DEFAULT 0',
      );
      await execute(
        'ALTER TABLE recipes ADD COLUMN IF NOT EXISTS fats_g INT DEFAULT 0',
      );
    } catch (e) {
      debugPrint('ensureUserSyncSchema columns: $e');
    }
  }

  /// Totaux consommés aujourd'hui (kcal + macros).
  /// Priorité : slot_analysis_json (photo IA) > colonnes recipes (recette).
  Future<Map<String, int>> loadTodayConsumed() async {
    final rows = await query(r'''
      SELECT
        COALESCE(SUM(CASE
          WHEN mp.slot_analysis_json IS NOT NULL
            THEN (mp.slot_analysis_json->>'kcal')::int
          ELSE COALESCE(r.calories, 0)
        END), 0) AS kcal,
        COALESCE(SUM(CASE
          WHEN mp.slot_analysis_json IS NOT NULL
            THEN (mp.slot_analysis_json->>'proteins')::int
          ELSE COALESCE(r.protein_g, 0)
        END), 0) AS proteins,
        COALESCE(SUM(CASE
          WHEN mp.slot_analysis_json IS NOT NULL
            THEN (mp.slot_analysis_json->>'carbs')::int
          ELSE COALESCE(r.carbs_g, 0)
        END), 0) AS carbs,
        COALESCE(SUM(CASE
          WHEN mp.slot_analysis_json IS NOT NULL
            THEN (mp.slot_analysis_json->>'fats')::int
          ELSE COALESCE(r.fats_g, 0)
        END), 0) AS fats
      FROM meal_plans mp
      LEFT JOIN recipes r ON r.id = mp.recipe_id
      WHERE mp.user_id = $1::uuid
        AND mp.date = CURRENT_DATE
    ''', [kUserId]);
    if (rows.isEmpty) return {'kcal': 0, 'proteins': 0, 'carbs': 0, 'fats': 0};
    final r = rows.first;
    return {
      'kcal':     (r['kcal']     as num?)?.toInt() ?? 0,
      'proteins': (r['proteins'] as num?)?.toInt() ?? 0,
      'carbs':    (r['carbs']    as num?)?.toInt() ?? 0,
      'fats':     (r['fats']     as num?)?.toInt() ?? 0,
    };
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
CREATE TABLE IF NOT EXISTS goals (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal TEXT NOT NULL,
  CONSTRAINT goals_one_row_per_user UNIQUE (user_id)
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_cooking_levels (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  cooking_level TEXT NOT NULL
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_fridge_ingredients (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  ingredient_name TEXT NOT NULL,
  PRIMARY KEY (user_id, ingredient_name)
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_photos (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  photo_base64 TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
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
CREATE TABLE IF NOT EXISTS kitchen_equipments (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_kitchen_equipments (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  equipment_id INT NOT NULL REFERENCES kitchen_equipments(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, equipment_id)
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
CREATE TABLE IF NOT EXISTS user_theme_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  theme_preference TEXT NOT NULL DEFAULT 'light',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_theme_preferences_valid_theme
    CHECK (theme_preference IN ('light', 'dark'))
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_ai_tone_preferences (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  ai_tone TEXT NOT NULL DEFAULT 'chef',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_ai_tone_preferences_valid_tone
    CHECK (ai_tone IN ('coach', 'chef', 'ami'))
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS user_push_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
)
''');

    await run('''
CREATE TABLE IF NOT EXISTS recipes (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  image_url TEXT,
  duration INT NOT NULL DEFAULT 0,
  calories INT NOT NULL DEFAULT 0,
  prep_time_min INT NOT NULL DEFAULT 0,
  rest_time_min INT NOT NULL DEFAULT 0,
  cook_time_min INT NOT NULL DEFAULT 0,
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

  // ── DAILY HERO RECIPES ─────────────────────────────────────────────────────

  Future<({List<Meal> meals, DateTime refreshedAt})?> loadHeroRecipes() async {
    final rows = await query(
      '''
      SELECT recipes_json::text AS recipes_json, refreshed_at::text AS refreshed_at
      FROM daily_hero_recipes
      WHERE user_id = \$1::uuid
      LIMIT 1
      ''',
      [kUserId],
    );
    if (rows.isEmpty) return null;
    final raw = rows.first['recipes_json'];
    final tsRaw = rows.first['refreshed_at'];
    if (raw == null || tsRaw == null) return null;
    final refreshedAt = DateTime.parse(tsRaw.toString());
    final decoded = jsonDecode(raw.toString()) as List<dynamic>;
    final meals = decoded
        .map((e) => Meal.fromJson(e as Map<String, dynamic>))
        .toList();
    return (meals: meals, refreshedAt: refreshedAt);
  }

  Future<void> saveHeroRecipes(List<Meal> meals) async {
    await _ensureUserRowExists();
    await execute(
      '''
      INSERT INTO daily_hero_recipes (user_id, recipes_json, refreshed_at)
      VALUES (\$1::uuid, \$2::jsonb, now())
      ON CONFLICT (user_id) DO UPDATE SET
        recipes_json = EXCLUDED.recipes_json,
        refreshed_at = now()
      ''',
      [kUserId, jsonEncode(meals.map((m) => m.toJson()).toList())],
    );
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
    final map = <String, Meal>{};
    for (final m in existing) {
      final id = normalizeRecipeId(m.id);
      map[id] = m.copyWith(id: id);
    }
    for (final m in newMeals) {
      final id = normalizeRecipeId(m.id);
      map[id] = m.copyWith(id: id);
    }
    final encoded =
        jsonEncode(map.values.map((m) => m.toJson()).toList(growable: false));
    await execute(
      'UPDATE users SET scan_meals_json = \$1 WHERE id = \$2',
      [encoded, kUserId],
    );
  }

  Future<List<Meal>> loadAdaptedMeals() async {
    final rows = await query(
      'SELECT adapted_meals_json FROM users WHERE id = \$1',
      [kUserId],
    );
    if (rows.isEmpty) return [];
    final raw = rows.first['adapted_meals_json'];
    if (raw == null) return [];
    final str = raw.toString();
    if (str.isEmpty) return [];
    final decoded = jsonDecode(str);
    if (decoded is! List) return [];
    return decoded
        .map((e) => Meal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveAdaptedMeals(List<Meal> meals) async {
    final encoded = jsonEncode(meals.map((m) => m.toJson()).toList());
    await execute(
      'UPDATE users SET adapted_meals_json = \$1 WHERE id = \$2',
      [encoded, kUserId],
    );
  }

  Future<void> saveFridgeIngredients(List<String> items) async {
    await _ensureUserRowExists();
    await execute(
      'DELETE FROM user_fridge_ingredients WHERE user_id = \$1::uuid',
      [kUserId],
    );
    for (final item in items) {
      final name = item.trim();
      if (name.isEmpty) continue;
      await execute(
        '''
        INSERT INTO user_fridge_ingredients (user_id, ingredient_name)
        VALUES (\$1::uuid, \$2)
        ON CONFLICT DO NOTHING
        ''',
        [kUserId, name],
      );
    }

    // Compat ancien stockage JSON.
    await execute(
      'UPDATE users SET fridge_ingredients_json = \$1 WHERE id = \$2',
      [jsonEncode(items), kUserId],
    );
  }

  Future<List<String>> loadFridgeIngredients() async {
    final relRows = await query(
      '''
      SELECT ingredient_name
      FROM user_fridge_ingredients
      WHERE user_id = \$1::uuid
      ORDER BY ingredient_name
      ''',
      [kUserId],
    );
    if (relRows.isNotEmpty) {
      return relRows
          .map((r) => (r['ingredient_name'] as String?) ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }

    // Fallback JSON ancien format.
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
    await _ensureUserRowExists();
    await execute('DELETE FROM meal_plans WHERE user_id = \$1::uuid', [kUserId]);
    for (final entry in selections.entries) {
      final sep = entry.key.indexOf('_');
      if (sep <= 0 || sep >= entry.key.length - 1) continue;
      final date = entry.key.substring(0, sep);
      final mealType = entry.key.substring(sep + 1);
      final meal = entry.value;
      await upsertRecipe(meal);
      await execute(
        '''
        INSERT INTO meal_plans (user_id, date, meal_type, recipe_id)
        VALUES (\$1::uuid, \$2::date, \$3, \$4::uuid)
        ON CONFLICT (user_id, date, meal_type) DO UPDATE SET
          recipe_id = EXCLUDED.recipe_id
        ''',
        [kUserId, date, mealType, normalizeRecipeId(meal.id)],
      );
    }

    // Compat ancien stockage JSON.
    final payload = jsonEncode(
      selections.map((k, v) => MapEntry(k, v.toJson())),
    );
    await execute(
      'UPDATE users SET plan_selections_json = \$1 WHERE id = \$2',
      [payload, kUserId],
    );
  }

  Future<Map<String, Meal>?> loadPlanSelections() async {
    final planRows = await query(
      '''
      SELECT date::text AS date, meal_type, recipe_id::text AS recipe_id
      FROM meal_plans
      WHERE user_id = \$1::uuid
      ORDER BY date, meal_type
      ''',
      [kUserId],
    );
    if (planRows.isNotEmpty) {
      final favSet = (await getFavoriteIds()).toSet();
      final out = <String, Meal>{};
      for (final row in planRows) {
        final date = row['date'] as String?;
        final mealType = row['meal_type'] as String?;
        final recipeId = row['recipe_id'] as String?;
        if (date == null || mealType == null || recipeId == null) continue;
        final meal = await _loadRecipeMeal(recipeId, favSet.contains(recipeId));
        if (meal == null) continue;
        out['${date}_$mealType'] = meal;
      }
      return out;
    }

    // Fallback JSON ancien format.
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

  // ── PLAN SLOT PHOTOS & ANALYSES ────────────────────────────────────────────

  Future<void> savePlanSlotPhoto(
      String slotKey, Uint8List bytes, Map<String, dynamic>? analysis) async {
    await _ensureUserRowExists();
    final sep = slotKey.indexOf('_');
    final date = slotKey.substring(0, sep);
    final mealType = slotKey.substring(sep + 1);
    final photoB64 = base64Encode(bytes);
    final analysisJson = analysis != null ? jsonEncode(analysis) : null;
    await execute('''
      INSERT INTO meal_plans (user_id, date, meal_type, slot_photo_base64, slot_analysis_json)
      VALUES (\$1::uuid, \$2::date, \$3, \$4, \$5::jsonb)
      ON CONFLICT (user_id, date, meal_type) DO UPDATE SET
        slot_photo_base64  = EXCLUDED.slot_photo_base64,
        slot_analysis_json = EXCLUDED.slot_analysis_json
    ''', [kUserId, date, mealType, photoB64, analysisJson]);
  }

  Future<void> removePlanSlotPhoto(String slotKey) async {
    final sep = slotKey.indexOf('_');
    final date = slotKey.substring(0, sep);
    final mealType = slotKey.substring(sep + 1);
    await execute('''
      UPDATE meal_plans
      SET slot_photo_base64 = NULL, slot_analysis_json = NULL
      WHERE user_id = \$1::uuid AND date = \$2::date AND meal_type = \$3
    ''', [kUserId, date, mealType]);
    await execute('''
      DELETE FROM meal_plans
      WHERE user_id = \$1::uuid AND date = \$2::date AND meal_type = \$3
        AND recipe_id IS NULL
    ''', [kUserId, date, mealType]);
  }

  Future<Map<String, ({Uint8List? photo, Map<String, dynamic>? analysis})>>
      loadPlanSlotExtras() async {
    final rows = await query('''
      SELECT date::text AS date, meal_type,
             slot_photo_base64,
             slot_analysis_json::text AS slot_analysis_json
      FROM meal_plans
      WHERE user_id = \$1::uuid
        AND (slot_photo_base64 IS NOT NULL OR slot_analysis_json IS NOT NULL)
    ''', [kUserId]);

    final result =
        <String, ({Uint8List? photo, Map<String, dynamic>? analysis})>{};
    for (final row in rows) {
      final date = row['date'] as String?;
      final mealType = row['meal_type'] as String?;
      if (date == null || mealType == null) continue;
      final key = '${date}_$mealType';
      final photoB64 = row['slot_photo_base64'] as String?;
      final analysisRaw = row['slot_analysis_json'] as String?;
      final photo = photoB64 != null ? base64Decode(photoB64) : null;
      final analysis = analysisRaw != null
          ? jsonDecode(analysisRaw) as Map<String, dynamic>?
          : null;
      result[key] = (photo: photo, analysis: analysis);
    }
    return result;
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
      const streakReset = 1;
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
