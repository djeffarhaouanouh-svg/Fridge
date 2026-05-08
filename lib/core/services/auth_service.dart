import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'neon_service.dart';

class AuthResult {
  final String? error;
  final String? userId;
  final String? name;
  final String? email;
  const AuthResult({this.error, this.userId, this.name, this.email});
  bool get success => error == null;
}

class AuthService {
  static const _kUserId = 'auth_user_id';
  static const _kUserName = 'auth_user_name';
  static const _kUserEmail = 'auth_user_email';

  static String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  // ── Initialise la colonne password_hash si elle n'existe pas ──────────────

  static Future<void> ensureSchema() async {
    try {
      await NeonService().execute(
        'ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT',
      );
    } catch (_) {}
  }

  // ── Inscription ───────────────────────────────────────────────────────────

  static Future<AuthResult> register(
      String name, String email, String password) async {
    await ensureSchema();
    final db = NeonService();
    try {
      final existing = await db.query(
        'SELECT id FROM users WHERE email = \$1',
        [email],
      );
      if (existing.isNotEmpty) {
        return const AuthResult(error: 'Cet email est déjà utilisé.');
      }
      final userId = const Uuid().v4();
      await db.execute('''
        INSERT INTO users (id, name, email, password_hash)
        VALUES (\$1, \$2, \$3, \$4)
      ''', [userId, name, email, _hash(password)]);
      await _saveSession(userId, name, email);
      return AuthResult(userId: userId, name: name, email: email);
    } catch (e) {
      return AuthResult(error: e.toString());
    }
  }

  // ── Connexion ─────────────────────────────────────────────────────────────

  static Future<AuthResult> login(String email, String password) async {
    await ensureSchema();
    final db = NeonService();
    try {
      final rows = await db.query(
        'SELECT id::text, name FROM users WHERE email = \$1 AND password_hash = \$2',
        [email, _hash(password)],
      );
      if (rows.isEmpty) {
        return const AuthResult(error: 'Email ou mot de passe incorrect.');
      }
      final userId = rows.first['id'] as String;
      final name = rows.first['name'] as String? ?? email.split('@').first;
      await _saveSession(userId, name, email);
      return AuthResult(userId: userId, name: name, email: email);
    } catch (e) {
      return AuthResult(error: e.toString());
    }
  }

  // ── Session ───────────────────────────────────────────────────────────────

  static Future<void> _saveSession(
      String userId, String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kUserName, name);
    await prefs.setString(_kUserEmail, email);
    NeonService.setCurrentUser(userId);
  }

  static Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_kUserId);
    if (userId == null) return null;
    final name = prefs.getString(_kUserName) ?? '';
    final email = prefs.getString(_kUserEmail) ?? '';
    NeonService.setCurrentUser(userId);
    return {'id': userId, 'name': name, 'email': email};
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kUserEmail);
    NeonService.clearCurrentUser();
  }

  static Future<void> autoRegister(String name) async {
    final userId = const Uuid().v4();
    final shortId = userId.replaceAll('-', '').substring(0, 10);
    final email = 'user-$shortId@fridge.local';
    final db = NeonService();
    try {
      await db.execute('''
        INSERT INTO users (id, name, email)
        VALUES (\$1, \$2, \$3)
        ON CONFLICT (id) DO NOTHING
      ''', [userId, name, email]);
    } catch (_) {}
    await _saveSession(userId, name, email);
  }

  static Future<void> updateName(String userId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, name);
  }

  static Future<void> updateEmail(String userId, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserEmail, email);
  }
}
