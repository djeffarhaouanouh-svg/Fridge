import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GoogleVisionService {
  static const _visionApiKey = String.fromEnvironment('GOOGLE_VISION_API_KEY');
  static const _endpoint =
      'https://vision.googleapis.com/v1/images:annotate';

  GoogleVisionService();

  Future<List<String>> detectIngredients(Uint8List imageBytes) async {
    if (_visionApiKey.isEmpty) {
      throw Exception('GOOGLE_VISION_API_KEY is missing.');
    }

    final response = await http.post(
      Uri.parse('$_endpoint?key=$_visionApiKey'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Encode(imageBytes)},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 20},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 20},
            ],
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Google Vision ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final responses = (data['responses'] as List?) ?? const [];
    if (responses.isEmpty) return [];
    final first = responses.first as Map<String, dynamic>;

    if (first['error'] != null) {
      throw Exception('Google Vision error: ${jsonEncode(first['error'])}');
    }

    try {
      final out = <String>[];
      final seen = <String>{};

      final labels = (first['labelAnnotations'] as List?) ?? const [];
      for (final item in labels) {
        final desc = ((item as Map)['description'] ?? '').toString().trim();
        if (desc.isEmpty) continue;
        final key = desc.toLowerCase();
        if (seen.add(key)) out.add(desc);
      }

      final objects = (first['localizedObjectAnnotations'] as List?) ?? const [];
      for (final item in objects) {
        final name = ((item as Map)['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        if (seen.add(key)) out.add(name);
      }

      return out;
    } catch (_) {
      return [];
    }
  }
}
