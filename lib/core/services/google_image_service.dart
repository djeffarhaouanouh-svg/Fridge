import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleImageService {
  static const _frToEn = {
    'poulet': 'chicken', 'blanc de poulet': 'chicken', 'escalope': 'chicken',
    'porc': 'pork', 'côtes de porc': 'pork', 'boeuf': 'beef', 'veau': 'veal',
    'agneau': 'lamb', 'saumon': 'salmon', 'thon': 'tuna', 'crevettes': 'shrimp',
    'pâtes': 'pasta', 'pasta': 'pasta', 'spaghetti': 'spaghetti',
    'gnocchi': 'gnocchi', 'riz': 'rice', 'quiche': 'quiche',
    'fromage': 'cheese', 'tomate': 'tomato', 'œuf': 'egg', 'oeuf': 'egg',
    'jambon': 'ham', 'mortadelle': 'sausage', 'lardons': 'bacon',
    'champignon': 'mushroom', 'épinards': 'spinach', 'courgette': 'zucchini',
    'curry': 'curry', 'soupe': 'soup', 'tarte': 'pie', 'pizza': 'pizza',
    'burger': 'burger', 'wrap': 'wrap', 'crêpe': 'crepe',
  };

  Future<String> searchFoodImage(String mealTitle) async {
    final titleLower = mealTitle.toLowerCase();
    String searchTerm = '';

    for (final entry in _frToEn.entries) {
      if (titleLower.contains(entry.key)) {
        searchTerm = entry.value;
        break;
      }
    }

    if (searchTerm.isEmpty) return _picsum(mealTitle);

    try {
      final resp = await http.get(Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=$searchTerm',
      ));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final meals = data['meals'] as List?;
        if (meals != null && meals.isNotEmpty) {
          return (meals.first['strMealThumb'] as String?) ?? _picsum(mealTitle);
        }
      }
    } catch (_) {}

    return _picsum(mealTitle);
  }

  String _picsum(String title) {
    final seed = Uri.encodeComponent(title);
    return 'https://picsum.photos/seed/$seed/600/400';
  }
}
