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
    ('bolognese', 'spaghetti bolognese.png'),
    ('carbonara', 'spaghetti carbonara.png'),
    ('gnocchi', 'gnocchi-saucetomate.png'),
    ('farfalle', 'icon.js/farfalle.png'),
    ('basilic', 'pates-basilic.png'),
    ('sauce tomate', 'pates-saucetomate.png'),
    ('saucetomate', 'pates-saucetomate.png'),
    ('tomate', 'pate-saucetomate.png'),
    ('spaghetti', 'spaghetti carbonara-2.png'),
    ('pates', 'pates-saucetomate.png'),
    ('pâtes', 'pates-saucetomate.png'),
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
