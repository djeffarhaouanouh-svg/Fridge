import 'auth_service.dart';

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
    final session = await AuthService.getSession();
    if (session != null) {
      return UserInfo(
        name: session['name'] ?? 'Utilisateur',
        email: session['email'] ?? '',
      );
    }
    return const UserInfo(name: 'Invité', email: '');
  }
}
