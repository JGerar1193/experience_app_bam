class User {
  final String name;
  final String email;
  final String role;

  const User({
    required this.name,
    required this.email,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';
}
