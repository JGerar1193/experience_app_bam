import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/user.dart';

class AuthLocalDatasource {
  final SharedPreferences _prefs;

  static const _usersKey = 'auth_users';
  static const _currentUserKey = 'auth_current_user';

  const AuthLocalDatasource(this._prefs);

  // Retorna el usuario actualmente autenticado, o null si no hay sesión activa
  User? getCurrentUser() {
    final email = _prefs.getString(_currentUserKey);
    if (email == null) return null;

    final users = _loadUsers();
    try {
      final userData = users.firstWhere((u) => u['email'] == email);
      return User(
        name: userData['name'] as String,
        email: email,
        role: userData['role'] as String? ?? 'user',
      );
    } catch (_) {
      return null;
    }
  }

  // Valida credenciales y persiste la sesión activa
  Future<User> login({required String email, required String password}) async {
    final users = _loadUsers();

    final match = users.where(
      (u) => u['email'] == email && u['password'] == password,
    );

    if (match.isEmpty) {
      throw Exception('Correo o contraseña incorrectos.');
    }

    final userData = match.first;
    await _prefs.setString(_currentUserKey, email);

    return User(
      name: userData['name'] as String,
      email: email,
      role: userData['role'] as String? ?? 'user',
    );
  }

  // Guarda un nuevo usuario y persiste la sesión activa
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = _loadUsers();

    final alreadyExists = users.any((u) => u['email'] == email);
    if (alreadyExists) {
      throw Exception('Ya existe una cuenta con ese correo.');
    }

    users.add({'name': name, 'email': email, 'password': password, 'role': 'user'});
    await _saveUsers(users);
    await _prefs.setString(_currentUserKey, email);

    return User(name: name, email: email, role: 'user');
  }

  // Limpia la sesión activa
  Future<void> logout() async {
    await _prefs.remove(_currentUserKey);
  }

  // ── helpers privados ────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _loadUsers() {
    final raw = _prefs.getString(_usersKey);
    if (raw == null) return [];

    final List<dynamic> decoded = json.decode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    await _prefs.setString(_usersKey, json.encode(users));
  }
}
