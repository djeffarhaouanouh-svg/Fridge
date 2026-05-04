import 'package:dio/dio.dart';
import '../../features/meals/models/meal.dart';

class SpoonacularService {
  // Clé gratuite depuis https://spoonacular.com/food-api (150 points/jour)
  static const _apiKey = String.fromEnvironment('SPOONACULAR_KEY');

  final _dio = Dio(BaseOptions(baseUrl: 'https://api.spoonacular.com'));

  Future<List<Meal>> findByIngredients(List<String> ingredients) async {
    // Étape 1 : trouver les recettes qui matchent les ingrédients
    final searchResp = await _dio.get(
      '/recipes/findByIngredients',
      queryParameters: {
        'ingredients': ingredients.join(','),
        'number': 3,
        'ranking': 1, // maximise les ingrédients utilisés
        'ignorePantry': true,
        'apiKey': _apiKey,
      },
    );

    final results = searchResp.data as List;
    if (results.isEmpty) return [];

    final ids = results.map((r) => r['id']).join(',');

    // Étape 2 : récupérer les détails complets en une seule requête
    final detailsResp = await _dio.get(
      '/recipes/informationBulk',
      queryParameters: {
        'ids': ids,
        'includeNutrition': true,
        'apiKey': _apiKey,
      },
    );

    return (detailsResp.data as List)
        .asMap()
        .entries
        .map((e) => _mapToMeal(e.value, e.key))
        .toList();
  }

  Meal _mapToMeal(Map<String, dynamic> r, int index) {
    final nutrients = (r['nutrition']?['nutrients'] as List? ?? []);

    num _nutrient(String name) => (nutrients.firstWhere(
          (n) => n['name'] == name,
          orElse: () => {'amount': 0},
        )['amount'] as num);

    final calories = _nutrient('Calories');
    final protein = _nutrient('Protein');

    final steps = ((r['analyzedInstructions'] as List?)?.isNotEmpty == true
            ? (r['analyzedInstructions'][0]['steps'] as List)
                .map((s) => s['step'] as String)
                .toList()
            : <String>[]);

    final ingredients = (r['extendedIngredients'] as List? ?? [])
        .map((i) => Ingredient(
              name: i['name'] ?? '',
              qty: '${i['amount']} ${i['unit']}'.trim(),
              photo: i['image'] != null
                  ? 'https://spoonacular.com/cdn/ingredients_100x100/${i['image']}'
                  : '',
            ))
        .toList();

    final time = (r['readyInMinutes'] as int?) ?? 30;
    final dishTypes = (r['dishTypes'] as List?)?.cast<String>() ?? [];

    String type, typeLabel, emoji, color;
    if (index == 0 || time <= 20) {
      type = 'simple'; typeLabel = 'Rapide'; emoji = '🍳'; color = '#C8B060';
    } else if (index == 2 || dishTypes.contains('dessert')) {
      type = 'stylish'; typeLabel = 'Stylé'; emoji = '😈'; color = '#C070C8';
    } else {
      type = 'balanced'; typeLabel = 'Équilibré'; emoji = '⚖️'; color = '#82D28C';
    }

    return Meal(
      id: r['id'].toString(),
      type: type,
      typeLabel: typeLabel,
      emoji: emoji,
      title: r['title'] ?? '',
      kcal: calories.round(),
      protein: protein > 20 ? 'élevé' : 'moyen',
      difficulty: time <= 20 ? 'facile' : 'intermédiaire',
      time: '$time min',
      locked: index == 2,
      photo: r['image'] ?? '',
      ingredients: ingredients,
      steps: steps,
      color: color,
    );
  }
}
