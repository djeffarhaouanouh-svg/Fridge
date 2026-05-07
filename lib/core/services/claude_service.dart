import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../features/meals/models/meal.dart';
import '../../features/plan/models/day_plan.dart';
import '../../features/profile/providers/profile_provider.dart';

class ClaudeService {
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _openAiBaseUrl = 'https://api.openai.com/v1/chat/completions';
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
    'assets/images/spaghetti-bolognese.png',
    'assets/images/spaghetti-carbonara.png',
    'assets/images/spaghetti-carbonara-2.png',
    'assets/images/gnocchi-saucetomate.png',
    'assets/images/pates-basilic.png',
    'assets/images/pates-saucetomate.png',
    'assets/images/pate-saucetomate.png',
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

  String _goalValue(UserProfile? p) {
    if (p?.objective == null) return 'non précisé';
    return switch (p!.objective!) {
      CookingObjective.weightLoss => 'Perte de poids',
      CookingObjective.muscleGain => 'Prise de muscle',
      CookingObjective.family => 'Cuisine familiale',
      CookingObjective.passion => 'Passion culinaire',
    };
  }

  String _cookingLevelValue(UserProfile? p) {
    if (p?.cookingLevel == null) return 'non précisé';
    return switch (p!.cookingLevel!) {
      CookingLevel.beginner => 'débutant',
      CookingLevel.intermediate => 'intermédiaire',
      CookingLevel.advanced => 'avancé',
      CookingLevel.expert => 'expert',
    };
  }

  String _joinOrNone(Iterable<String> values) =>
      values.isEmpty ? 'aucun' : values.join(', ');

  String _buildRecipesPrompt({
    required List<String> ingredients,
    required UserProfile? profile,
  }) {
    return '''Tu es un assistant culinaire intelligent spécialisé dans les recettes réalistes.

MISSION :
Créer des recettes cohérentes, populaires et réellement cuisinables à partir des ingrédients détectés dans le frigo de l'utilisateur.

DONNÉES UTILISATEUR :
- Objectif : ${_goalValue(profile)}
- Niveau de cuisine : ${_cookingLevelValue(profile)}
- Allergies : ${_joinOrNone(profile?.allergies ?? const <String>{})}
- Régime alimentaire : ${_joinOrNone(profile?.diets ?? const <String>{})}
- Équipements disponibles : ${_joinOrNone(profile?.kitchenEquipments ?? const <String>{})}

INGRÉDIENTS DISPONIBLES :
${ingredients.join(', ')}

RÈGLES IMPORTANTES :
- Proposer uniquement des recettes réalistes et crédibles
- Éviter les plats inventés ou les associations étranges
- Favoriser les recettes populaires et connues
- Adapter la difficulté au niveau utilisateur
- Respecter STRICTEMENT le régime alimentaire et les allergies
- Utiliser uniquement les équipements disponibles
- Prioriser les ingrédients disponibles
- Si des ingrédients manquent, les indiquer clairement
- Éviter les recettes impossibles avec les ingrédients présents
- Les recettes doivent donner envie et sembler naturelles
- Ne jamais inventer des techniques culinaires absurdes

STYLE :
- Moderne
- Clair
- Appétissant
- Naturel
- Humain

FORMAT JSON :
[
  {
    "title": "",
    "description": "",
    "time": "",
    "difficulty": "",
    "calories": "",
    "missingIngredients": [],
    "ingredientsUsed": [],
    "steps": [],
    "whyThisRecipeFitsUser": ""
  }
]

Contraintes supplémentaires :
- Retourne exactement 3 recettes
- Retourne UNIQUEMENT le JSON, sans texte autour.''';
  }

  List<Meal> _mapPromptRecipesToMeals(List<dynamic> recipes) {
    const uuid = Uuid();
    const cardMeta = <(String, String, String, String, bool)>[
      ('simple', 'Rapide', '🍳', '#C8B060', false),
      ('balanced', 'Équilibré', '⚖️', '#82D28C', false),
      ('stylish', 'Stylé', '😈', '#C070C8', true),
    ];

    final meals = <Meal>[];
    for (var i = 0; i < recipes.length && i < 3; i++) {
      final raw = Map<String, dynamic>.from(recipes[i] as Map);
      final meta = cardMeta[i];
      final ingredientsUsed =
          ((raw['ingredientsUsed'] as List?) ?? const []).map((e) => e.toString()).toList();
      final steps = ((raw['steps'] as List?) ?? const []).map((e) => e.toString()).toList();
      final kcal = int.tryParse((raw['calories'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final time = (raw['time'] ?? '30 min').toString();
      final difficulty = (raw['difficulty'] ?? 'facile').toString().toLowerCase();

      meals.add(Meal(
        id: uuid.v4(),
        type: meta.$1,
        typeLabel: meta.$2,
        emoji: meta.$3,
        title: (raw['title'] ?? '').toString(),
        kcal: kcal,
        protein: 'moyen',
        difficulty: difficulty.contains('inter') ? 'intermédiaire' : 'facile',
        time: time,
        locked: meta.$5,
        photo: '',
        ingredients: ingredientsUsed
            .map((name) => Ingredient(name: name, qty: '', photo: ''))
            .toList(),
        steps: steps,
        color: meta.$4,
      ));
    }
    return meals;
  }

  Future<List<Meal>> findRecipes(List<String> ingredients, {UserProfile? profile}) async {
    if (_openAiApiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY is missing.');
    }

    final prompt = _buildRecipesPrompt(
      ingredients: ingredients,
      profile: profile,
    );

    final response = await http.post(
      Uri.parse(_openAiBaseUrl),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $_openAiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4.1-mini',
        'max_tokens': 2500,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'OpenAI recipes ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = (data['choices'] as List?) ?? const [];
    if (choices.isEmpty) return [];
    final first = choices.first as Map<String, dynamic>;
    final message = (first['message'] as Map<String, dynamic>?) ?? const {};
    final text = (message['content'] ?? '')
        .toString()
        .replaceAll(RegExp(r'```json|```'), '')
        .trim();

    final List<dynamic> recipes = jsonDecode(text);
    final meals = _mapPromptRecipesToMeals(recipes);

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
