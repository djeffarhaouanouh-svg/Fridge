import 'package:flutter/material.dart';

String getIngredientCategory(String name) {
  final n = name.toLowerCase();

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
      n.contains('nouille')) {
    return 'pates';
  }

  if (n.contains('poulet') ||
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
      n.contains('bacon')) {
    return 'viande';
  }

  if (n.contains('saumon') ||
      n.contains('thon') ||
      n.contains('cabillaud') ||
      n.contains('crevette') ||
      n.contains('poisson') ||
      n.contains('moule') ||
      n.contains('calamar') ||
      n.contains('merlu')) {
    return 'poisson';
  }

  if (n.contains('oeuf') ||
      n.contains('œuf')) {
    return 'oeufs';
  }

  if (n.contains('lait') ||
      n.contains('fromage') ||
      n.contains('beurre') ||
      n.contains('crème') ||
      n.contains('creme') ||
      n.contains('yaourt') ||
      n.contains('mozzarella') ||
      n.contains('parmesan') ||
      n.contains('gruyère') ||
      n.contains('ricotta')) {
    return 'laitier';
  }

  if (n.contains('tomate') ||
      n.contains('carotte') ||
      n.contains('courgette') ||
      n.contains('brocoli') ||
      n.contains('épinard') ||
      n.contains('epinard') ||
      n.contains('poivron') ||
      n.contains('oignon') ||
      n.contains('ail') ||
      n.contains('champignon') ||
      n.contains('salade') ||
      n.contains('concombre') ||
      n.contains('aubergine') ||
      n.contains('poireau') ||
      n.contains('céleri') ||
      n.contains('celeri') ||
      n.contains('navet') ||
      n.contains('haricot') ||
      n.contains('petits pois') ||
      n.contains('maïs') ||
      n.contains('legume') ||
      n.contains('légume')) {
    return 'legumes';
  }

  if (n.contains('pomme') ||
      n.contains('banane') ||
      n.contains('fraise') ||
      n.contains('citron') ||
      n.contains('orange') ||
      n.contains('mangue') ||
      n.contains('fruit') ||
      n.contains('raisin') ||
      n.contains('ananas') ||
      n.contains('cerise')) {
    return 'fruits';
  }

  if (n.contains('riz') ||
      n.contains('quinoa') ||
      n.contains('couscous') ||
      n.contains('boulgour') ||
      n.contains('semoule') ||
      n.contains('orge') ||
      n.contains('lentille') ||
      n.contains('pois chiche') ||
      n.contains('fève')) {
    return 'cereales';
  }

  if (n.contains('pain') ||
      n.contains('baguette') ||
      n.contains('farine') ||
      n.contains('brioche') ||
      n.contains('croissant')) {
    return 'boulangerie';
  }

  return 'default';
}

Widget buildIngredientIcon(String ingredientName) {
  final category = getIngredientCategory(ingredientName);

  if (category == 'pates') {
    return Image.asset(
      'assets/icons/farfalle.png',
      width: 26,
      height: 26,
      fit: BoxFit.contain,
    );
  }

  final Map<String, String> categoryEmojis = {
    'viande': '🥩',
    'poisson': '🐟',
    'oeufs': '🥚',
    'laitier': '🧀',
    'legumes': '🥦',
    'fruits': '🍎',
    'cereales': '🌾',
    'boulangerie': '🍞',
    'default': '🫙',
  };

  return Text(
    categoryEmojis[category] ?? '🫙',
    style: const TextStyle(fontSize: 22),
  );
}
