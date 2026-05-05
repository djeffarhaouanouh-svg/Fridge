import 'package:flutter/foundation.dart';
import 'neon_service.dart';

/// Enregistre la liste d’ingrédients du frigo côté Neon (appel explicite + listeners).
Future<void> persistFridgeToNeon(List<String> items) async {
  try {
    await NeonService().saveFridgeIngredients(items);
  } catch (e, st) {
    debugPrint('persistFridgeToNeon: $e\n$st');
  }
}
