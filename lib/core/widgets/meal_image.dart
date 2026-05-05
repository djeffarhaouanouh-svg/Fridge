import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_tokens.dart';

class MealImage extends StatelessWidget {
  final String photo;
  final BoxFit fit;

  const MealImage({super.key, required this.photo, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (photo.isEmpty) {
      return Container(color: AppTokens.placeholder);
    }

    if (photo.startsWith('assets/')) {
      return Image.asset(photo, fit: fit);
    }

    return CachedNetworkImage(
      imageUrl: photo,
      fit: fit,
      placeholder: (_, __) => Container(color: AppTokens.placeholder),
      errorWidget: (_, __, ___) => Container(color: AppTokens.placeholder),
    );
  }
}
