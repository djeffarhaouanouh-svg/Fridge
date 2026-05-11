import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const _kKey = 'fridge_ingredient_dates';
const _kExpiryDays = 3;

/// Enregistre la date d'ajout (aujourd'hui) pour [names].
Future<void> recordIngredientsAdded(Iterable<String> names) async {
  final prefs = await SharedPreferences.getInstance();
  final dates = _load(prefs);
  final today = _today();
  for (final n in names) {
    final key = n.trim().toLowerCase();
    if (key.isNotEmpty) dates[key] = today;
  }
  await prefs.setString(_kKey, jsonEncode(dates));
}

/// Supprime la date enregistrée pour [name].
Future<void> removeIngredientDate(String name) async {
  final prefs = await SharedPreferences.getInstance();
  final dates = _load(prefs);
  dates.remove(name.trim().toLowerCase());
  await prefs.setString(_kKey, jsonEncode(dates));
}

/// Retourne uniquement les ingrédients dont la date est < 3 jours.
/// Les ingrédients sans date (ajoutés avant la feature) sont conservés.
Future<List<String>> filterFresh(List<String> ingredients) async {
  final prefs = await SharedPreferences.getInstance();
  final dates = _load(prefs);
  final cutoff = DateTime.now().subtract(const Duration(days: _kExpiryDays));
  return ingredients.where((ing) {
    final dateStr = dates[ing.trim().toLowerCase()];
    if (dateStr == null) return true;
    final date = DateTime.tryParse(dateStr);
    return date == null || date.isAfter(cutoff);
  }).toList();
}

Map<String, String> _load(SharedPreferences prefs) {
  try {
    final raw = prefs.getString(_kKey);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  } catch (_) {
    return {};
  }
}

String _today() => DateTime.now().toIso8601String().substring(0, 10);
