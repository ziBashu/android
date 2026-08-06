class AuthSession {
  const AuthSession({
    required this.token,
    this.name,
    this.email,
  });

  final String token;
  final String? name;
  final String? email;

  bool get isAuthenticated => token.isNotEmpty;
}
