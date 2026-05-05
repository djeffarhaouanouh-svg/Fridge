import 'package:firebase_auth/firebase_auth.dart';

class UserInfo {
  final String name;
  final String email;
  const UserInfo({required this.name, required this.email});
}

class UserService {
  static final UserService _instance = UserService._();
  factory UserService() => _instance;
  UserService._();

  Future<UserInfo> fetchUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return UserInfo(
        name: user.displayName ?? user.email?.split('@').first ?? 'Utilisateur',
        email: user.email ?? '',
      );
    }
    return const UserInfo(name: 'Invité', email: '');
  }
}
