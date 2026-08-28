import '../entities/card_validation_result.dart';
import '../repositories/card_repository.dart';

class ValidateCardUseCase {
  final CardRepository repository;

  const ValidateCardUseCase(this.repository);

  CardValidationResult call({
    required String cardNumber,
    required double amount,
  }) {
    return repository.validate(cardNumber, amount);
  }
}
