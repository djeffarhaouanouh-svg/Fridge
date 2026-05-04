import 'dart:convert';
import 'package:http/http.dart' as http;

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
    'moutarde': 'mustard', 'beurre': 'butter',
  };

  Future<String> searchFoodImage(String mealTitle) async {
    final titleLower = mealTitle.toLowerCase();
    String ingredient = 'chicken';

    for (final entry in _frToEn.entries) {
      if (titleLower.contains(entry.key)) {
        ingredient = entry.value;
        break;
      }
    }

    try {
      final uri = Uri.https('www.themealdb.com', '/api/json/v1/1/filter.php', {
        'i': ingredient,
      });
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final meals = data['meals'] as List?;
        if (meals != null && meals.isNotEmpty) {
          return (meals.first['strMealThumb'] as String?) ?? '';
        }
      }
    } catch (_) {}

    return 'https://picsum.photos/seed/${Uri.encodeComponent(mealTitle)}/600/400';
  }
}
