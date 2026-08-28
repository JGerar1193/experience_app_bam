import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/user.dart';

/// Thrown when Firebase cannot reach the network, allowing the repository
/// to fall back to local authentication.
class FirebaseNetworkException implements Exception {
  const FirebaseNetworkException();
}

class AuthFirebaseDatasource {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthFirebaseDatasource({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Returns the currently signed-in user with role, or null.
  Future<User?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    final role = await _fetchRole(fbUser.uid);
    return User(
      name: fbUser.displayName ?? fbUser.email!.split('@')[0],
      email: fbUser.email!,
      role: role,
    );
  }

  Future<User> login({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user!;
      final role = await _fetchRole(fbUser.uid);
      return User(
        name: fbUser.displayName ?? fbUser.email!.split('@')[0],
        email: fbUser.email!,
        role: role,
      );
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const FirebaseNetworkException();
      }
      throw Exception(_mapError(e.code));
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);
      // Crea el documento del usuario en Firestore con rol 'user' por defecto
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return User(name: name, email: credential.user!.email!, role: 'user');
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const FirebaseNetworkException();
      }
      throw Exception(_mapError(e.code));
    }
  }

  Future<void> logout() => _auth.signOut();

  /// Lee el rol desde Firestore. Si el documento no existe o hay error, retorna 'user'.
  Future<String> _fetchRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'] as String? ?? 'user';
    } catch (_) {
      return 'user';
    }
  }

  String _mapError(String code) {
    return switch (code) {
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'Correo o contraseña incorrectos.',
      'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
      'invalid-email' => 'El formato del correo es inválido.',
      'too-many-requests' => 'Demasiados intentos. Intenta más tarde.',
      'user-disabled' => 'Esta cuenta ha sido deshabilitada.',
      _ => 'Error de autenticación: $code',
    };
  }
}
