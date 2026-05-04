import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleImageService {
  static const _apiKey = String.fromEnvironment('GOOGLE_CSE_KEY');
  static const _cx = String.fromEnvironment('GOOGLE_CSE_ID');

  Future<String> searchFoodImage(String query) async {
    if (_apiKey.isEmpty || _cx.isEmpty) return '';
    try {
      final uri = Uri.https('www.googleapis.com', '/customsearch/v1', {
        'q': '$query recette',
        'searchType': 'image',
        'cx': _cx,
        'key': _apiKey,
        'num': '1',
        'imgSize': 'large',
        'imgType': 'photo',
        'safe': 'active',
      });
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          return (items.first['link'] as String?) ?? '';
        }
      }
    } catch (_) {}
    return '';
  }
}
