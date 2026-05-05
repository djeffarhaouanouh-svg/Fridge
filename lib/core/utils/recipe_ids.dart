import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Colonnes `recipes.id` / `favorites.recipe_id` sont des UUID Postgres.
/// Spoonacular renvoie des ids numériques ; on les dérive en UUID v5 stables.
String normalizeRecipeId(String rawId) {
  final s = rawId.trim();
  if (Uuid.isValidUUID(fromString: s)) return s;
  return _uuid.v5(Namespace.url.value, 'fridge-recipe:$s');
}
