import '../entities/card_validation_result.dart';
import '../entities/payment_card.dart';

abstract class CardRepository {
  /// Retorna todas las tarjetas de prueba del mock.
  List<PaymentCard> getTestCards();

  /// Valida si un número de tarjeta puede procesar un cobro de [amount].
  CardValidationResult validate(String cardNumber, double amount);
}
