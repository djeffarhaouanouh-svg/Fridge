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
    String keyword = mealTitle;

    for (final entry in _frToEn.entries) {
      if (titleLower.contains(entry.key)) {
        keyword = entry.value;
        break;
      }
    }

    return 'https://source.unsplash.com/600x400/?food,${Uri.encodeComponent(keyword)}';
  }
}
