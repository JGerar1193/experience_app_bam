import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_firebase_datasource.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthFirebaseDatasource _firebase;
  final AuthLocalDatasource _local;

  const AuthRepositoryImpl({
    required AuthFirebaseDatasource firebase,
    required AuthLocalDatasource local,
  })  : _firebase = firebase,
        _local = local;

  @override
  Future<User?> getCurrentUser() async {
    return await _firebase.getCurrentUser() ?? _local.getCurrentUser();
  }

  @override
  Future<User> login({required String email, required String password}) async {
    try {
      return await _firebase.login(email: email, password: password);
    } on FirebaseNetworkException {
      // Firebase unreachable — fall back to locally stored credentials
      return _local.login(email: email, password: password);
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = await _firebase.register(
      name: name,
      email: email,
      password: password,
    );
    // Mirror locally so the user can log in offline after registration
    try {
      await _local.register(name: name, email: email, password: password);
    } catch (_) {}
    return user;
  }

  @override
  Future<void> logout() async {
    await _firebase.logout();
    await _local.logout();
  }
}

