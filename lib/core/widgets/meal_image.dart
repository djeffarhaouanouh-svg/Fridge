import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

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
    ('bolognese', 'assets/images/spaghetti-bolognese.png'),
    ('bolognaise', 'assets/images/spaghetti-bolognese.png'),
    ('boeuf tomate', 'assets/images/spaghetti-bolognese.png'),
    ('bœuf tomate', 'assets/images/spaghetti-bolognese.png'),
    ('viande hachee', 'assets/images/spaghetti-bolognese.png'),
    ('viande hachée', 'assets/images/spaghetti-bolognese.png'),

    // Carbonara / lardons
    ('carbonara', 'assets/images/spaghetti-carbonara.png'),
    ('carbo', 'assets/images/spaghetti-carbonara.png'),
    ('lardons', 'assets/images/spaghetti-carbonara.png'),
    ('jambon creme', 'assets/images/spaghetti-carbonara.png'),
    ('jambon crème', 'assets/images/spaghetti-carbonara.png'),

    // Gnocchi / tomate
    ('gnocchi', 'assets/images/gnocchi-saucetomate.png'),
    ('gnocchis', 'assets/images/gnocchi-saucetomate.png'),
    ('gnocchi tomate', 'assets/images/gnocchi-saucetomate.png'),

    // Farfalle
    ('farfalle', 'icon.js/farfalle.png'),

    // Basilic / pesto-ish
    ('basilic', 'assets/images/pates-basilic.png'),
    ('pesto', 'assets/images/pates-basilic.png'),
    ('verde', 'assets/images/pates-basilic.png'),

    // Sauce tomate / pasta rouge
    ('sauce tomate', 'assets/images/pates-saucetomate.png'),
    ('saucetomate', 'assets/images/pates-saucetomate.png'),
    ('pates tomate', 'assets/images/pates-saucetomate.png'),
    ('pâtes tomate', 'assets/images/pates-saucetomate.png'),
    ('pasta tomate', 'assets/images/pates-saucetomate.png'),
    ('napolitaine', 'assets/images/pates-saucetomate.png'),
    ('arrabiata', 'assets/images/pates-saucetomate.png'),
    ('arrabbiata', 'assets/images/pates-saucetomate.png'),

    // Tomate générique
    ('tomate', 'assets/images/pate-saucetomate.png'),
    ('tomates', 'assets/images/pate-saucetomate.png'),

    // Spaghetti / pâtes génériques
    ('spaghetti', 'assets/images/spaghetti-carbonara-2.png'),
    ('spaghettis', 'assets/images/spaghetti-carbonara-2.png'),
    ('pasta', 'assets/images/spaghetti-carbonara-2.png'),
    ('pates', 'assets/images/pates-saucetomate.png'),
    ('pâtes', 'assets/images/pates-saucetomate.png'),
    ('penne', 'assets/images/pates-saucetomate.png'),
    ('tagliatelle', 'assets/images/pates-saucetomate.png'),
    ('linguine', 'assets/images/pates-saucetomate.png'),
    ('macaroni', 'assets/images/pates-saucetomate.png'),
    ('nouilles', 'assets/images/pates-saucetomate.png'),
    ('nouille', 'assets/images/pates-saucetomate.png'),
    ('lasagne', 'assets/images/pates-saucetomate.png'),
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
    final cs = Theme.of(context).colorScheme;
    // Avoid solid gray/colored blocks while decoding — parent (card) shows through.
    final subtleErrorBg = cs.brightness == Brightness.dark
        ? cs.surfaceContainerHighest
        : cs.surface;

    final localAsset = _guessLocalAsset();

    if (photo.isEmpty) {
      if (localAsset != null) {
        return Image.asset(
          localAsset,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => ColoredBox(color: subtleErrorBg),
        );
      }
      return ColoredBox(color: subtleErrorBg);
    }

    if (photo.startsWith('assets/')) {
      return Image.asset(
        photo,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => ColoredBox(color: subtleErrorBg),
      );
    }

    if (_looksLikeFilePath(photo)) {
      return Image.file(
        File(photo),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => ColoredBox(color: subtleErrorBg),
      );
    }

    if (localAsset != null) {
      return Image.asset(
        localAsset,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => ColoredBox(color: subtleErrorBg),
      );
    }

    return CachedNetworkImage(
      imageUrl: photo,
      fit: fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      memCacheWidth: 800,
      useOldImageOnUrlChange: true,
      placeholder: (_, __) => const ColoredBox(color: Colors.transparent),
      errorWidget: (_, __, ___) => ColoredBox(color: subtleErrorBg),
    );
  }

  bool _looksLikeFilePath(String value) {
    if (value.startsWith('/') || value.startsWith(r'\\')) return true;
    final windowsPathRegex = RegExp(r'^[a-zA-Z]:[\\/]');
    return windowsPathRegex.hasMatch(value);
  }
}
