import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_tokens.dart';

class MealImage extends StatelessWidget {
  final String photo;
  final String? fallbackKey;
  final BoxFit fit;

  const MealImage({
    super.key,
    required this.photo,
    this.fallbackKey,
    this.fit = BoxFit.cover,
  });

  static const List<(String, String)> _localRecipePhotoRules = [
    // Bolognese / viande tomate
    ('bolognese', 'spaghetti bolognese.png'),
    ('bolognaise', 'spaghetti bolognese.png'),
    ('boeuf tomate', 'spaghetti bolognese.png'),
    ('bœuf tomate', 'spaghetti bolognese.png'),
    ('viande hachee', 'spaghetti bolognese.png'),
    ('viande hachée', 'spaghetti bolognese.png'),

    // Carbonara / lardons
    ('carbonara', 'spaghetti carbonara.png'),
    ('carbo', 'spaghetti carbonara.png'),
    ('lardons', 'spaghetti carbonara.png'),
    ('jambon creme', 'spaghetti carbonara.png'),
    ('jambon crème', 'spaghetti carbonara.png'),

    // Gnocchi / tomate
    ('gnocchi', 'gnocchi-saucetomate.png'),
    ('gnocchis', 'gnocchi-saucetomate.png'),
    ('gnocchi tomate', 'gnocchi-saucetomate.png'),

    // Farfalle
    ('farfalle', 'icon.js/farfalle.png'),

    // Basilic / pesto-ish
    ('basilic', 'pates-basilic.png'),
    ('pesto', 'pates-basilic.png'),
    ('verde', 'pates-basilic.png'),

    // Sauce tomate / pasta rouge
    ('sauce tomate', 'pates-saucetomate.png'),
    ('saucetomate', 'pates-saucetomate.png'),
    ('pates tomate', 'pates-saucetomate.png'),
    ('pâtes tomate', 'pates-saucetomate.png'),
    ('pasta tomate', 'pates-saucetomate.png'),
    ('napolitaine', 'pates-saucetomate.png'),
    ('arrabiata', 'pates-saucetomate.png'),
    ('arrabbiata', 'pates-saucetomate.png'),

    // Tomate générique
    ('tomate', 'pate-saucetomate.png'),
    ('tomates', 'pate-saucetomate.png'),

    // Spaghetti / pâtes génériques
    ('spaghetti', 'spaghetti carbonara-2.png'),
    ('spaghettis', 'spaghetti carbonara-2.png'),
    ('pasta', 'spaghetti carbonara-2.png'),
    ('pates', 'pates-saucetomate.png'),
    ('pâtes', 'pates-saucetomate.png'),
    ('penne', 'pates-saucetomate.png'),
    ('tagliatelle', 'pates-saucetomate.png'),
    ('linguine', 'pates-saucetomate.png'),
    ('macaroni', 'pates-saucetomate.png'),
    ('nouilles', 'pates-saucetomate.png'),
    ('nouille', 'pates-saucetomate.png'),
    ('lasagne', 'pates-saucetomate.png'),
  ];

  String? _guessLocalAsset() {
    final seed = '${photo.toLowerCase()} ${(fallbackKey ?? '').toLowerCase()}';
    for (final (keyword, assetPath) in _localRecipePhotoRules) {
      if (seed.contains(keyword)) return assetPath;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final localAsset = _guessLocalAsset();

    if (photo.isEmpty) {
      if (localAsset != null) {
        return Image.asset(
          localAsset,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => Container(color: AppTokens.placeholder),
        );
      }
      return Container(color: AppTokens.placeholder);
    }

    if (photo.startsWith('assets/')) {
      return Image.asset(
        photo,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(color: AppTokens.placeholder),
      );
    }

    if (localAsset != null) {
      return Image.asset(
        localAsset,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(color: AppTokens.placeholder),
      );
    }

    return CachedNetworkImage(
      imageUrl: photo,
      fit: fit,
      placeholder: (_, __) => Container(color: AppTokens.placeholder),
      errorWidget: (_, __, ___) => Container(color: AppTokens.placeholder),
    );
  }
}
