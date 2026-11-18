import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_firebase_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthFirebaseDatasource _firebase;

  const AuthRepositoryImpl({required AuthFirebaseDatasource firebase})
      : _firebase = firebase;

  @override
  Future<User?> getCurrentUser() => _firebase.getCurrentUser();

  @override
  Future<User> login({required String email, required String password}) {
    return _firebase.login(email: email, password: password);
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _firebase.register(name: name, email: email, password: password);
  }

  @override
  Future<void> sendPasswordReset({required String email}) {
    return _firebase.sendPasswordReset(email: email);
  }

  @override
  Future<void> logout() => _firebase.logout();
}

