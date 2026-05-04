import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_secrets.dart';

class GoogleImageService {
  static const _frToEn = {
    'poulet': 'chicken', 'blanc de poulet': 'chicken', 'escalope': 'chicken',
    'filet de poulet': 'chicken', 'cuisse': 'chicken',
    'porc': 'pork', 'lardons': 'bacon', 'boeuf': 'beef', 'steak': 'beef',
    'veau': 'veal', 'agneau': 'lamb', 'saumon': 'salmon', 'thon': 'tuna',
    'crevettes': 'shrimp', 'gnocchi': 'gnocchi', 'pâtes': 'pasta',
    'pasta': 'pasta', 'spaghetti': 'spaghetti', 'riz': 'rice',
    'risotto': 'risotto', 'pizza': 'pizza', 'burger': 'burger',
    'quiche': 'quiche', 'tarte': 'pie', 'crêpe': 'crepe',
    'fromage': 'cheese', 'tomate': 'tomato', 'œuf': 'egg', 'oeuf': 'egg',
    'omelette': 'omelette', 'jambon': 'ham', 'mortadelle': 'salami',
    'champignon': 'mushroom', 'curry': 'curry', 'soupe': 'soup',
    'moutarde': 'mustard sauce', 'beurre': 'butter sauce',
  };

  Future<String> searchFoodImage(String mealTitle) async {
    final titleLower = mealTitle.toLowerCase();
    String query = mealTitle;

    for (final entry in _frToEn.entries) {
      if (titleLower.contains(entry.key)) {
        query = entry.value;
        break;
      }
    }

    try {
      final uri = Uri.https('api.pexels.com', '/v1/search', {
        'query': '$query food recipe',
        'per_page': '1',
        'orientation': 'square',
      });
      final resp = await http.get(uri, headers: {
        'Authorization': kPexelsKey,
      });
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final photos = data['photos'] as List?;
        if (photos != null && photos.isNotEmpty) {
          return (photos.first['src']['medium'] as String?) ?? '';
        }
      }
    } catch (_) {}

    return 'https://picsum.photos/seed/${Uri.encodeComponent(mealTitle)}/600/400';
  }
}
