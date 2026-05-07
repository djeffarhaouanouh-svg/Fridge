import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GoogleVisionService {
  static const _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  GoogleVisionService();

  Future<List<String>> detectIngredients(Uint8List imageBytes) async {
    if (_openAiApiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY is missing.');
    }

    final dataUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $_openAiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Liste les aliments visibles dans cette image. '
                        'Retourne UNIQUEMENT un tableau JSON de chaînes en français. '
                        'Exemple: ["tomates","oeufs","fromage"].',
              },
              {
                'type': 'image_url',
                'image_url': {'url': dataUrl},
              }
            ],
          },
        ],
        'max_tokens': 300,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI vision ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = (data['choices'] as List?) ?? const [];
    if (choices.isEmpty) return [];
    final first = choices.first as Map<String, dynamic>;
    final message = (first['message'] as Map<String, dynamic>?) ?? const {};
    final content = (message['content'] ?? '').toString();

    try {
      final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();
      return (jsonDecode(cleaned) as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
