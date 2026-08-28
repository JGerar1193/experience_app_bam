import '../entities/payment_response.dart';
import '../repositories/payment_repository.dart';

class ProcessPaymentUseCase {
  final PaymentRepository repository;

  const ProcessPaymentUseCase(this.repository);

  Future<PaymentResponse> call({
    required String cardNumber,
    required double amount,
    String currency = 'USD',
  }) {
    return repository.processPayment(
      cardNumber: cardNumber,
      amount: amount,
      currency: currency,
    );
  }
}
