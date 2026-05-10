import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OpenAiVisionService {
  static const _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  OpenAiVisionService();

  Future<List<String>> detectIngredients(List<Uint8List> images) async {
    if (_openAiApiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY is missing.');
    }

    final content = <Map<String, dynamic>>[
      {
        'type': 'text',
        'text': 'Liste tous les aliments visibles dans ces images. '
            'Retourne UNIQUEMENT un tableau JSON de chaînes en français, sans doublons. '
            'Exemple: ["tomates","oeufs","fromage"].',
      },
      ...images.map((bytes) => {
        'type': 'image_url',
        'image_url': {
          'url': 'data:image/jpeg;base64,${base64Encode(bytes)}',
          'detail': 'low',
        },
      }),
    ];

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'content-type': 'application/json',
        'authorization': 'Bearer $_openAiApiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': content},
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
    final text = (message['content'] ?? '').toString();

    try {
      final cleaned = text.replaceAll(RegExp(r'```json|```'), '').trim();
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
