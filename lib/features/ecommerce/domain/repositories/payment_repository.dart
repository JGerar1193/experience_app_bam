import '../entities/payment_response.dart';

abstract class PaymentRepository {
  /// Llama al servicio remoto para procesar el pago.
  Future<PaymentResponse> processPayment({
    required String cardNumber,
    required double amount,
    String currency,
  });
}
