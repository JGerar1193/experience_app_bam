import '../../domain/entities/payment_response.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDatasource _datasource;

  PaymentRepositoryImpl(this._datasource);

  @override
  Future<PaymentResponse> processPayment({
    required String cardNumber,
    required double amount,
    String currency = 'USD',
  }) async {
    final model = await _datasource.processPayment(
      cardNumber: cardNumber,
      amount: amount,
      currency: currency,
    );
    return model.toEntity();
  }
}
