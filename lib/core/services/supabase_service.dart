import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/meals/models/meal.dart';

// Config Supabase — récupère ces valeurs dans ton dashboard :
// https://supabase.com/dashboard → Settings → API
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

// SQL à exécuter dans Supabase → SQL Editor pour créer la table :
// create table saved_recipes (
//   id uuid default gen_random_uuid() primary key,
//   meal_id text not null,
//   meal_data jsonb not null,
//   saved_at timestamptz default now()
// );

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> saveRecipe(Meal meal) async {
    await _client.from('saved_recipes').upsert({
      'meal_id': meal.id,
      'meal_data': meal.toJson(),
      'saved_at': DateTime.now().toIso8601String(),
    }, onConflict: 'meal_id');
  }

  static Future<List<Meal>> getSavedRecipes() async {
    final response = await _client
        .from('saved_recipes')
        .select()
        .order('saved_at', ascending: false);

    return (response as List)
        .map((r) => Meal.fromJson(r['meal_data'] as Map<String, dynamic>))
        .toList();
  }
}
