import '../models/meal.dart';

/// Recettes par defaut affichees avant le premier scan utilisateur.
final List<Meal> kDefaultMockMeals = [
  Meal(
    id: '8bdbf553-4aa0-4be9-9b84-8f3e6d5e8a01',
    type: 'simple',
    typeLabel: 'Rapide',
    emoji: '🍗',
    title: 'Blanc de Poulet aux Gnocchi Fritti et Legumes',
    kcal: 713,
    protein: 'eleve',
    difficulty: 'facile',
    time: '35 min',
    locked: false,
    photo:
        'https://images.unsplash.com/photo-1604908554027-5fc40d4f57f9?w=1200&q=80&auto=format&fit=crop',
    ingredients: [
      Ingredient(name: 'Blanc de poulet', qty: '2 pieces', photo: ''),
      Ingredient(name: 'Gnocchi', qty: '300 g', photo: ''),
      Ingredient(name: 'Courgette', qty: '1', photo: ''),
      Ingredient(name: 'Poivron', qty: '1', photo: ''),
    ],
    steps: [
      'Assaisonne le poulet avec sel et poivre.',
      'Poele le poulet 5 a 6 minutes par face puis reserve.',
      'Fais dorer les gnocchi dans la meme poele.',
      'Ajoute les legumes eminces et remets le poulet pour terminer la cuisson.',
    ],
    color: '#C8B060',
  ),
  Meal(
    id: '2d3319bf-c6d1-4ab7-8f56-f7af93786d92',
    type: 'balanced',
    typeLabel: 'Equilibre',
    emoji: '😈',
    title: 'Gnocchi Fritti en Croute d Oeuf et Jambon',
    kcal: 540,
    protein: 'moyen',
    difficulty: 'intermediaire',
    time: '40 min',
    locked: false,
    photo:
        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=1200&q=80&auto=format&fit=crop',
    ingredients: [
      Ingredient(name: 'Gnocchi', qty: '350 g', photo: ''),
      Ingredient(name: 'Jambon', qty: '120 g', photo: ''),
      Ingredient(name: 'Oeufs', qty: '2', photo: ''),
      Ingredient(name: 'Parmesan', qty: '30 g', photo: ''),
    ],
    steps: [
      'Fais cuire les gnocchi puis egoutte-les.',
      'Bats les oeufs avec parmesan, sel et poivre.',
      'Poele jambon puis ajoute les gnocchi pour les saisir.',
      'Verse les oeufs battus et laisse prendre en melangeant doucement.',
    ],
    color: '#82D28C',
  ),
  Meal(
    id: '6318bb14-2cce-49f0-b988-c5ef6fbe5b20',
    type: 'stylish',
    typeLabel: 'Style',
    emoji: '🍝',
    title: 'Pates au Beurre et Jambon Croustillant',
    kcal: 460,
    protein: 'moyen',
    difficulty: 'facile',
    time: '20 min',
    locked: false,
    photo:
        'https://images.unsplash.com/photo-1555949258-eb67b1ef0ceb?w=1200&q=80&auto=format&fit=crop',
    ingredients: [
      Ingredient(name: 'Pates', qty: '250 g', photo: ''),
      Ingredient(name: 'Beurre', qty: '25 g', photo: ''),
      Ingredient(name: 'Jambon', qty: '100 g', photo: ''),
      Ingredient(name: 'Poivre', qty: '1 pincee', photo: ''),
    ],
    steps: [
      'Fais cuire les pates al dente.',
      'Poele rapidement le jambon pour le rendre croustillant.',
      'Ajoute beurre et un peu d eau de cuisson aux pates.',
      'Mele le jambon croustillant et sers avec poivre noir.',
    ],
    color: '#C070C8',
  ),
];
