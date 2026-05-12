import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connexion / session locale (voir [AuthGate] dans `main.dart`).
final authStateProvider = StateProvider<bool>((ref) => false);
