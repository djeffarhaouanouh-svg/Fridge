import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../features/meals/models/meal.dart';

class ClaudeService {
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5-20251001';

  Map<String, String> get _headers => {
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
        'content-type': 'application/json',
      };

  String _mediaType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'image/jpeg';
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
                    'List all food ingredients visible in this image. Return ONLY a JSON array of strings in English, example: ["chicken","rice","tomatoes"]. Nothing else.',
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

  Future<List<Meal>> findRecipes(List<String> ingredients) async {
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
    "locked": false,
    "photo": "https://source.unsplash.com/featured/600x400/?food,KEYWORD",
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
- protein: "moyen" or "élevé"
- difficulty: "facile" or "intermédiaire"
- For "photo": replace KEYWORD with 1-2 English food words describing the dish (e.g. "banana,toast" or "smoothie,bowl")
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

    final List<dynamic> recipes = jsonDecode(text);
    return recipes.map((r) => Meal.fromJson(r as Map<String, dynamic>)).toList();
  }
}
