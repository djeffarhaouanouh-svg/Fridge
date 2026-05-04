import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleImageService {
  static const _frToEn = {
    'poulet': 'chicken', 'blanc de poulet': 'chicken', 'escalope': 'chicken',
    'filet de poulet': 'chicken', 'cuisse': 'chicken',
    'porc': 'pork', 'côtes de porc': 'pork', 'lardons': 'bacon',
    'boeuf': 'beef', 'steak': 'beef', 'veau': 'veal', 'agneau': 'lamb',
    'saumon': 'salmon', 'thon': 'tuna', 'crevettes': 'shrimp',
    'pâtes': 'pasta', 'pasta': 'pasta', 'spaghetti': 'spaghetti',
    'tagliatelle': 'pasta', 'penne': 'pasta',
    'gnocchi': 'pasta',
    'riz': 'rice', 'risotto': 'risotto',
    'pizza': 'pizza', 'burger': 'burger', 'wrap': 'wrap',
    'quiche': 'quiche', 'tarte': 'pie', 'crêpe': 'crepe',
    'fromage': 'cheese', 'tomate': 'tomato',
    'œuf': 'egg', 'oeuf': 'egg', 'omelette': 'omelette',
    'jambon': 'ham', 'mortadelle': 'sausage',
    'champignon': 'mushroom', 'épinards': 'spinach',
    'curry': 'curry', 'soupe': 'soup',
  };

  static const _foodishMap = {
    'chicken': 'butter-chicken', 'pasta': 'pasta', 'spaghetti': 'pasta',
    'pizza': 'pizza', 'burger': 'burger', 'rice': 'rice', 'risotto': 'rice',
    'dessert': 'dessert', 'dosa': 'dosa', 'idly': 'idly',
  };

  Future<String> searchFoodImage(String mealTitle) async {
    final titleLower = mealTitle.toLowerCase();
    final enKeywords = <String>[];

    for (final entry in _frToEn.entries) {
      if (titleLower.contains(entry.key) && !enKeywords.contains(entry.value)) {
        enKeywords.add(entry.value);
      }
    }

    // Essai TheMealDB avec chaque mot-clé
    for (final kw in enKeywords) {
      final url = await _themealdb(kw);
      if (url.isNotEmpty) return url;
    }

    // Fallback Foodish (vraies photos food)
    final foodishCat = enKeywords
        .map((kw) => _foodishMap[kw])
        .firstWhere((c) => c != null, orElse: () => 'biryani') ?? 'biryani';
    final foodishUrl = await _foodish(foodishCat);
    if (foodishUrl.isNotEmpty) return foodishUrl;

    // Dernier recours : Picsum
    return 'https://picsum.photos/seed/${Uri.encodeComponent(mealTitle)}/600/400';
  }

  Future<String> _themealdb(String term) async {
    try {
      final resp = await http.get(Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=$term',
      ));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final meals = data['meals'] as List?;
        if (meals != null && meals.isNotEmpty) {
          return (meals.first['strMealThumb'] as String?) ?? '';
        }
      }
    } catch (_) {}
    return '';
  }

  Future<String> _foodish(String category) async {
    try {
      final resp = await http.get(Uri.parse(
        'https://foodish-api.com/api/images/$category',
      ));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return (data['image'] as String?) ?? '';
      }
    } catch (_) {}
    return '';
  }
}
