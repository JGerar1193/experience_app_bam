import '../repositories/auth_repository.dart';

class SendPasswordResetUseCase {
  final AuthRepository _repository;

  const SendPasswordResetUseCase(this._repository);

  Future<void> call({required String email}) {
    return _repository.sendPasswordReset(email: email);
  }
}
