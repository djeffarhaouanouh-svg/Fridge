import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../features/meals/models/meal.dart';
import '../../features/plan/models/day_plan.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../config/app_secrets.dart';

class ClaudeService {
  static const _apiKey = kAnthropicKey;
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  Map<String, String> get _headers => {
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
        'content-type': 'application/json',
      };

  static String _frDayName(DateTime date) {
    const names = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    return names[date.weekday - 1];
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _mediaType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'image/jpeg';
  }

  static const List<String> _uniquePhotoFallbackPool = [
    'spaghetti bolognese.png',
    'spaghetti carbonara.png',
    'spaghetti carbonara-2.png',
    'gnocchi-saucetomate.png',
    'pates-basilic.png',
    'pates-saucetomate.png',
    'pate-saucetomate.png',
    'icon.js/farfalle.png',
  ];

  String _normalizePhotoIdentity(String photo) {
    final raw = photo.trim().toLowerCase();
    if (raw.isEmpty) return '';
    // Unsplash: détecte l'ID de photo même avec query params différents.
    final unsplashId = RegExp(r'photo-[a-z0-9]+').firstMatch(raw)?.group(0);
    if (unsplashId != null) return unsplashId;
    return raw;
  }

  List<Meal> _ensureUniquePhotos(List<Meal> meals) {
    final used = <String>{};
    var fallbackIndex = 0;
    final result = <Meal>[];

    for (final meal in meals) {
      var chosen = meal.photo.trim();
      var key = _normalizePhotoIdentity(chosen);

      if (key.isEmpty || used.contains(key)) {
        while (fallbackIndex < _uniquePhotoFallbackPool.length) {
          final candidate = _uniquePhotoFallbackPool[fallbackIndex++];
          final candidateKey = _normalizePhotoIdentity(candidate);
          if (!used.contains(candidateKey)) {
            chosen = candidate;
            key = candidateKey;
            break;
          }
        }
      }

      if (key.isEmpty || used.contains(key)) {
        // Ultime sécurité: URL unique par id recette.
        chosen =
            'https://picsum.photos/seed/${Uri.encodeComponent(meal.id)}/800/600';
        key = _normalizePhotoIdentity(chosen);
      }

      used.add(key);
      result.add(meal.copyWith(photo: chosen));
    }
    return result;
  }

  Future<List<String>> detectIngredients(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    final mediaType = _mediaType(imageBytes);

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'model': _model,
        'max_tokens': 512,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': base64Image,
                },
              },
              {
                'type': 'text',
                'text':
                    'Liste tous les aliments visibles dans cette image. Retourne UNIQUEMENT un tableau JSON de chaînes en français, exemple: ["poulet","riz","tomates"]. Rien d\'autre.',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Claude vision ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = (data['content'][0]['text'] as String)
        .replaceAll(RegExp(r'```json|```'), '')
        .trim();

    return (jsonDecode(text) as List).cast<String>();
  }

  String _buildProfileContext(UserProfile? p) {
    if (p == null) return '';
    final parts = <String>[];
    if (p.objective != null) {
      parts.add(switch (p.objective!) {
        CookingObjective.weightLoss => 'The user wants to lose weight — prefer low-calorie, light recipes.',
        CookingObjective.muscleGain => 'The user wants to gain muscle — prefer high-protein recipes.',
        CookingObjective.family     => 'The user cooks for a family — prefer generous, family-friendly recipes.',
        CookingObjective.passion    => 'The user loves cooking — feel free to suggest elaborate recipes.',
      });
    }
    if (p.cookingLevel != null) {
      parts.add(switch (p.cookingLevel!) {
        CookingLevel.beginner     => 'Cooking level: beginner — keep steps simple.',
        CookingLevel.intermediate => 'Cooking level: intermediate.',
        CookingLevel.advanced     => 'Cooking level: advanced — complex techniques are welcome.',
        CookingLevel.expert       => 'Cooking level: expert chef.',
      });
    }
    if (p.diets.isNotEmpty) parts.add('Dietary preferences: ${p.diets.join(', ')}.');
    if (p.allergies.isNotEmpty) parts.add('ALLERGIES to avoid: ${p.allergies.join(', ')}.');
    if (p.targetCalories > 0) parts.add('Target: ~${p.targetCalories} kcal per meal.');
    if (parts.isEmpty) return '';
    return '\nUser context:\n${parts.map((s) => '- $s').join('\n')}\n';
  }

  Future<List<Meal>> findRecipes(List<String> ingredients, {UserProfile? profile}) async {
    final profileContext = _buildProfileContext(profile);
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'model': _model,
        'max_tokens': 4096,
        'messages': [
          {
            'role': 'user',
            'content': '''Based on these ingredients: ${ingredients.join(', ')}
$profileContext
Suggest 3 recipes. Return ONLY a JSON array with this exact structure:
[
  {
    "id": "1",
    "title": "Recipe Name",
    "type": "simple",
    "typeLabel": "Rapide",
    "emoji": "🍳",
    "color": "#C8B060",
    "kcal": 450,
    "protein": "moyen",
    "difficulty": "facile",
    "time": "25 min",
    "prepTimeMin": 10,
    "restTimeMin": 0,
    "cookTimeMin": 15,
    "locked": false,
    "photo": "https://images.unsplash.com/photo-XXXXXXXXXXXXXXXXXXX?w=600&q=80",
    "ingredients": [{"name": "chicken", "qty": "200g", "photo": ""}],
    "steps": ["Étape 1", "Étape 2"]
  }
]

Rules:
- Recipe 1: type="simple", typeLabel="Rapide", emoji="🍳", color="#C8B060", locked=false
- Recipe 2: type="balanced", typeLabel="Équilibré", emoji="⚖️", color="#82D28C", locked=false
- Recipe 3: type="stylish", typeLabel="Stylé", emoji="😈", color="#C070C8", locked=true
- 5-8 ingredients per recipe with quantities
- 4-6 cooking steps in French
- Include prepTimeMin, restTimeMin, cookTimeMin as integer minutes (>= 0)
- protein: "moyen" or "élevé"
- difficulty: "facile" or "intermédiaire"
- photo: a real images.unsplash.com URL with a valid photo ID matching the dish (e.g. pasta → photo-1621996346565-e3dbc646d9a9, chicken → photo-1598103442097-8b74394b95c1). Each recipe must have a different photo.
- Return ONLY the JSON array, nothing else.''',
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Claude recipes ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = (data['content'][0]['text'] as String)
        .replaceAll(RegExp(r'```json|```'), '')
        .trim();

    const uuid = Uuid();
    final List<dynamic> recipes = jsonDecode(text);
    final meals = recipes.map((e) {
      final raw = Map<String, dynamic>.from(e as Map);
      raw['id'] = uuid.v4();
      return Meal.fromJson(raw);
    }).toList();

    // Sécurité anti-doublon: aucune recette ne garde la même image qu'une autre.
    return _ensureUniquePhotos(meals);
  }

  Future<List<DayPlan>> generateWeekPlan(List<Uint8List> photos) async {
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final date = today.add(Duration(days: i));
      return '"${_isoDate(date)}" (${_frDayName(date)})';
    }).join(', ');

    final imageContent = photos.take(3).map((photo) => {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': _mediaType(photo),
            'data': base64Encode(photo),
          },
        }).toList();

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: jsonEncode({
        'model': _model,
        'max_tokens': 4096,
        'messages': [
          {
            'role': 'user',
            'content': [
              ...imageContent,
              {
                'type': 'text',
                'text': '''Based on the ingredients visible in these fridge photos, generate a meal plan for the next 7 days.

Days: $days

Return ONLY a JSON array with exactly 7 objects:
[
  {
    "day": "Samedi",
    "date": "2026-05-02",
    "lunch": {
      "name": "Salade de tomates",
      "kcal": 320,
      "time": "15 min",
      "steps": ["Étape 1 en français", "Étape 2 en français", "Étape 3 en français"]
    },
    "dinner": {
      "name": "Poulet rôti aux herbes",
      "kcal": 520,
      "time": "35 min",
      "steps": ["Étape 1 en français", "Étape 2 en français", "Étape 3 en français", "Étape 4 en français"]
    }
  }
]

Rules:
- Use mainly ingredients visible in the photos
- Meal names in French, concise (max 5 words)
- Vary meals across the week (no repetition)
- 3 to 5 cooking steps per meal, in French, clear and actionable
- kcal: realistic estimate between 250 and 800
- Return ONLY the JSON array, nothing else.''',
              },
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Claude plan ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final text = (data['content'][0]['text'] as String)
        .replaceAll(RegExp(r'```json|```'), '')
        .trim();

    final List<dynamic> plans = jsonDecode(text);
    return plans
        .map((p) => DayPlan.fromJson(p as Map<String, dynamic>))
        .toList();
  }
}
