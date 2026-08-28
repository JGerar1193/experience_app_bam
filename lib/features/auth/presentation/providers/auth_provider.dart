import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../data/datasources/auth_firebase_datasource.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'package:experience_app/features/ecommerce/presentation/providers/cart_provider.dart';

// ── Providers de infraestructura ──────────────────────────────────────────────

final authFirebaseDatasourceProvider = Provider<AuthFirebaseDatasource>((ref) {
  return AuthFirebaseDatasource();
});

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  return AuthLocalDatasource(ref.read(sharedPreferencesProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebase: ref.read(authFirebaseDatasourceProvider),
    local: ref.read(authLocalDatasourceProvider),
  );
});

// ── Providers de casos de uso ─────────────────────────────────────────────────

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.read(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.read(authRepositoryProvider));
});

// ── Estado de autenticación ───────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        errorMessage = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null;

  AuthState.authenticated(User u)
      : status = AuthStatus.authenticated,
        user = u,
        errorMessage = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = null;

  AuthState.error(String message)
      : status = AuthStatus.error,
        user = null,
        errorMessage = message;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final GetCurrentUserUseCase _getCurrentUser;

  AuthNotifier({
    required LoginUseCase login,
    required RegisterUseCase register,
    required LogoutUseCase logout,
    required GetCurrentUserUseCase getCurrentUser,
  })  : _login = login,
        _register = register,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        super(const AuthState.initial()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await _getCurrentUser();
    if (user != null) {
      state = AuthState.authenticated(user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = const AuthState.loading();
    try {
      final user = await _login(email: email, password: password);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _register(name: name, email: email, password: password);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.error(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await NotificationService.deleteToken();
    await _logout();
    state = const AuthState.unauthenticated();
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState.unauthenticated();
    }
  }
}

// ── Provider principal ────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    login: ref.read(loginUseCaseProvider),
    register: ref.read(registerUseCaseProvider),
    logout: ref.read(logoutUseCaseProvider),
    getCurrentUser: ref.read(getCurrentUserUseCaseProvider),
  );
});
