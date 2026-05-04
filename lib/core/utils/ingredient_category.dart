import 'package:flutter/material.dart';

String getIngredientCategory(String name) {
  final n = name.toLowerCase();

  // 🍝 Staples / Carbs
  if (n.contains('pate') ||
      n.contains('pâte') ||
      n.contains('spaghetti') ||
      n.contains('gnocchi') ||
      n.contains('penne') ||
      n.contains('tagliatelle') ||
      n.contains('linguine') ||
      n.contains('fusilli') ||
      n.contains('farfalle') ||
      n.contains('rigatoni') ||
      n.contains('lasagne') ||
      n.contains('macaroni') ||
      n.contains('nouille') ||
      n.contains('riz') ||
      n.contains('quinoa') ||
      n.contains('semoule') ||
      n.contains('couscous') ||
      n.contains('boulgour') ||
      n.contains('lentille') ||
      n.contains('pois chiche') ||
      n.contains('haricot rouge') ||
      n.contains('haricot blanc') ||
      n.contains('pomme de terre') ||
      n.contains('patate douce') ||
      n.contains('patate') ||
      n.contains('pain') ||
      n.contains('baguette') ||
      n.contains('brioche') ||
      n.contains('croissant')) {
    return 'staples';
  }

  // 🥩 Meat & Fish
  if (n.contains('poulet') ||
      n.contains('poule') ||
      n.contains('poitrine') ||
      n.contains('boeuf') ||
      n.contains('bœuf') ||
      n.contains('porc') ||
      n.contains('agneau') ||
      n.contains('veau') ||
      n.contains('steak') ||
      n.contains('viande') ||
      n.contains('saucisse') ||
      n.contains('jambon') ||
      n.contains('lardons') ||
      n.contains('bacon') ||
      n.contains('dinde') ||
      n.contains('canard') ||
      n.contains('lapin') ||
      n.contains('côte') ||
      n.contains('cote') ||
      n.contains('filet') ||
      n.contains('escalope') ||
      n.contains('saumon') ||
      n.contains('thon') ||
      n.contains('cabillaud') ||
      n.contains('crevette') ||
      n.contains('poisson') ||
      n.contains('moule') ||
      n.contains('calamar') ||
      n.contains('merlu') ||
      n.contains('sardine') ||
      n.contains('anchois')) {
    return 'viande';
  }

  // 🥚 Dairy & Eggs
  if (n.contains('oeuf') ||
      n.contains('œuf') ||
      n.contains('lait') ||
      n.contains('beurre') ||
      n.contains('crème') ||
      n.contains('creme') ||
      n.contains('yaourt') ||
      n.contains('yogourt')) {
    return 'laitier';
  }

  // 🧀 Cheese
  if (n.contains('fromage') ||
      n.contains('mozzarella') ||
      n.contains('parmesan') ||
      n.contains('gruyère') ||
      n.contains('gruyere') ||
      n.contains('cheddar') ||
      n.contains('camembert') ||
      n.contains('brie') ||
      n.contains('feta') ||
      n.contains('ricotta') ||
      n.contains('emmental') ||
      n.contains('comté') ||
      n.contains('comte') ||
      n.contains('roquefort')) {
    return 'fromage';
  }

  // 🥦 Vegetables
  if (n.contains('tomate') ||
      n.contains('salade') ||
      n.contains('laitue') ||
      n.contains('carotte') ||
      n.contains('oignon') ||
      n.contains('ail') ||
      n.contains('brocoli') ||
      n.contains('courgette') ||
      n.contains('aubergine') ||
      n.contains('poivron') ||
      n.contains('champignon') ||
      n.contains('concombre') ||
      n.contains('épinard') ||
      n.contains('epinard') ||
      n.contains('poireau') ||
      n.contains('céleri') ||
      n.contains('celeri') ||
      n.contains('navet') ||
      n.contains('haricot vert') ||
      n.contains('petits pois') ||
      n.contains('maïs') ||
      n.contains('mais') ||
      n.contains('artichaut') ||
      n.contains('asperge') ||
      n.contains('chou') ||
      n.contains('radis') ||
      n.contains('betterave') ||
      n.contains('légume') ||
      n.contains('legume')) {
    return 'legumes';
  }

  // 🍎 Fruits
  if (n.contains('pomme') ||
      n.contains('banane') ||
      n.contains('fraise') ||
      n.contains('citron') ||
      n.contains('orange') ||
      n.contains('mangue') ||
      n.contains('avocat') ||
      n.contains('kiwi') ||
      n.contains('ananas') ||
      n.contains('raisin') ||
      n.contains('cerise') ||
      n.contains('poire') ||
      n.contains('pêche') ||
      n.contains('peche') ||
      n.contains('abricot') ||
      n.contains('melon') ||
      n.contains('pastèque') ||
      n.contains('pasteque') ||
      n.contains('fruit')) {
    return 'fruits';
  }

  // 🍫 Snacks / Sweet
  if (n.contains('chocolat') ||
      n.contains('cookie') ||
      n.contains('bonbon') ||
      n.contains('gâteau') ||
      n.contains('gateau') ||
      n.contains('miel') ||
      n.contains('confiture') ||
      n.contains('biscuit') ||
      n.contains('chips') ||
      n.contains('caramel') ||
      n.contains('sucette') ||
      n.contains('tarte')) {
    return 'snack';
  }

  // 🧂 Condiments
  if (n.contains('sel') ||
      n.contains('poivre') ||
      n.contains('sucre') ||
      n.contains('farine') ||
      n.contains('huile') ||
      n.contains('vinaigre') ||
      n.contains('sauce tomate') ||
      n.contains('mayonnaise') ||
      n.contains('ketchup') ||
      n.contains('moutarde') ||
      n.contains('soja') ||
      n.contains('curry') ||
      n.contains('cumin') ||
      n.contains('paprika') ||
      n.contains('herbe') ||
      n.contains('épice') ||
      n.contains('epice') ||
      n.contains('persil') ||
      n.contains('basilic') ||
      n.contains('thym') ||
      n.contains('romarin')) {
    return 'condiment';
  }

  // 🥤 Drinks
  if (n.contains('eau') ||
      n.contains('jus') ||
      n.contains('soda') ||
      n.contains('café') ||
      n.contains('cafe') ||
      n.contains('thé') ||
      n.contains('the') ||
      n.contains('boisson') ||
      n.contains('limonade') ||
      n.contains('sirop')) {
    return 'boisson';
  }

  // ❄️ Frozen / Fast food
  if (n.contains('pizza') ||
      n.contains('nugget') ||
      n.contains('frites') ||
      n.contains('glace') ||
      n.contains('surgelé') ||
      n.contains('surgele') ||
      n.contains('burger')) {
    return 'surgele';
  }

  return 'default';
}

Widget buildIngredientIcon(String ingredientName) {
  final category = getIngredientCategory(ingredientName);

  const Map<String, String> categoryEmojis = {
    'staples': '🍝',
    'viande': '🥩',
    'laitier': '🥚',
    'fromage': '🧀',
    'legumes': '🥦',
    'fruits': '🍎',
    'snack': '🍫',
    'condiment': '🧂',
    'boisson': '🥤',
    'surgele': '❄️',
    'default': '🫙',
  };

  return Text(
    categoryEmojis[category] ?? '🫙',
    style: const TextStyle(fontSize: 22),
  );
}
