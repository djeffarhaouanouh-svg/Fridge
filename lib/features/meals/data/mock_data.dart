import '../models/meal.dart';

class MockData {
  static final List<Meal> meals = [
    Meal(
      id: '1',
      type: 'simple',
      typeLabel: 'Rapide',
      emoji: '🥱',
      title: 'Pâtes à l\'ail & parmesan',
      kcal: 480,
      protein: 'moyen',
      difficulty: 'facile',
      time: '12 min',
      locked: false,
      photo: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&h=800&fit=crop&q=80',
      ingredients: [
        Ingredient(
          name: 'Pâtes',
          qty: '200 g',
          photo: 'https://images.unsplash.com/photo-1551462147-ff29053bfc14?w=400&q=80',
        ),
        Ingredient(
          name: 'Ail',
          qty: '3 gousses',
          photo: 'https://images.unsplash.com/photo-1615477550927-6ec8da3b8ebd?w=400&q=80',
        ),
        Ingredient(
          name: 'Parmesan',
          qty: '40 g',
          photo: 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&q=80',
        ),
        Ingredient(
          name: 'Huile d\'olive',
          qty: '2 c. à s.',
          photo: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&q=80',
        ),
      ],
      steps: [
        'Fais cuire les pâtes 8 min dans l\'eau salée.',
        'Fais revenir 3 gousses d\'ail haché dans l\'huile.',
        'Mélange les pâtes égouttées avec l\'ail.',
        'Ajoute le parmesan et du poivre. C\'est prêt ! 🎉',
      ],
      color: '#C8B060',
    ),
    Meal(
      id: '2',
      type: 'balanced',
      typeLabel: 'Équilibré',
      emoji: '⚖️',
      title: 'Bol de riz au poulet',
      kcal: 520,
      protein: 'élevé',
      difficulty: 'facile',
      time: '20 min',
      locked: false,
      photo: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80',
      ingredients: [
        Ingredient(
          name: 'Riz',
          qty: '150 g',
          photo: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&q=80',
        ),
        Ingredient(
          name: 'Poulet',
          qty: '250 g',
          photo: 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400&q=80',
        ),
        Ingredient(
          name: 'Légumes',
          qty: '200 g',
          photo: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&q=80',
        ),
        Ingredient(
          name: 'Sauce soja',
          qty: '3 c. à s.',
          photo: 'https://images.unsplash.com/photo-1607301406259-dfb186e15de8?w=400&q=80',
        ),
      ],
      steps: [
        'Cuis le riz pendant 15 min.',
        'Coupe le poulet en dés et fais sauter 5 min.',
        'Ajoute les légumes et la sauce soja.',
        'Sers sur le riz. Bon appétit ! 🍚',
      ],
      color: '#82D28C',
    ),
    Meal(
      id: '3',
      type: 'stylish',
      typeLabel: 'Stylé',
      emoji: '😈',
      title: 'Gnocchis croustillants',
      kcal: 560,
      protein: 'moyen',
      difficulty: 'intermédiaire',
      time: '18 min',
      locked: true,
      photo: 'https://images.unsplash.com/photo-1587740908075-9e245070dfaa?w=800&q=80',
      ingredients: [
        Ingredient(
          name: 'Gnocchis',
          qty: '500 g',
          photo: 'https://images.unsplash.com/photo-1633855636644-5c43e83e9eaa?w=400&q=80',
        ),
        Ingredient(
          name: 'Beurre',
          qty: '40 g',
          photo: 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400&q=80',
        ),
        Ingredient(
          name: 'Sauge',
          qty: '8 feuilles',
          photo: 'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?w=400&q=80',
        ),
        Ingredient(
          name: 'Parmesan',
          qty: '30 g',
          photo: 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&q=80',
        ),
      ],
      steps: [],
      color: '#C070C8',
    ),
  ];

  static List<String> goals = [
    'Rapide',
    'Sain',
    'Fitness',
    'Stylé',
  ];

  static List<String> diets = [
    'Aucun',
    'Vegan',
    'Végé',
    'Sans gluten',
  ];
}
