class UserInfo {
  final String name;
  final String email;
  const UserInfo({required this.name, required this.email});
}

class UserService {
  static final UserService _instance = UserService._();
  factory UserService() => _instance;
  UserService._();

  // Remplacer par un vrai appel API quand le backend est prêt
  Future<UserInfo> fetchUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const UserInfo(
      name: 'Louis Dubois',
      email: 'louis@fridge.ai',
    );
  }
}
