import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleImageService {
  static const _apiKey = String.fromEnvironment('PIXABAY_KEY');

  Future<String> searchFoodImage(String query) async {
    if (_apiKey.isEmpty) return '';
    try {
      final uri = Uri.https('pixabay.com', '/api/', {
        'key': _apiKey,
        'q': query,
        'image_type': 'photo',
        'category': 'food',
        'min_width': '600',
        'per_page': '3',
        'safesearch': 'true',
      });
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final hits = data['hits'] as List?;
        if (hits != null && hits.isNotEmpty) {
          return (hits.first['largeImageURL'] as String?) ?? '';
        }
      }
    } catch (_) {}
    return '';
  }
}
