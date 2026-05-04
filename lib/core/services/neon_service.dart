import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_secrets.dart';

class NeonService {
  static const _host = 'ep-dawn-night-abd29yl2-pooler.eu-west-2.aws.neon.tech';
  static const _user = 'neondb_owner';

  static String get _auth =>
      'Basic ${base64Encode(utf8.encode('$_user:$kNeonPassword'))}';

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic> params = const [],
  ]) async {
    final resp = await http.post(
      Uri.https(_host, '/sql'),
      headers: {
        'Authorization': _auth,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'query': sql, 'params': params}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Neon ${resp.statusCode}: ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final rows = data['rows'] as List? ?? [];
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> execute(String sql, [List<dynamic> params = const []]) async {
    await query(sql, params);
  }

  Future<void> initDb() async {
    await execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        id TEXT PRIMARY KEY DEFAULT \'default\',
        objective TEXT,
        cooking_level TEXT,
        allergies JSONB DEFAULT \'[]\',
        diets JSONB DEFAULT \'[]\',
        target_calories INTEGER DEFAULT 2000,
        target_protein INTEGER DEFAULT 150,
        target_carbs INTEGER DEFAULT 200,
        target_fats INTEGER DEFAULT 65,
        updated_at TIMESTAMP DEFAULT NOW()
      )
    ''');
  }
}
