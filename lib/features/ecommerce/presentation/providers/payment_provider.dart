import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/process_payment_usecase.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  // Cierra el cliente cuando el provider se destruye
  ref.onDispose(client.close);
  return client;
});

final paymentDatasourceProvider = Provider<PaymentRemoteDatasource>((ref) {
  return PaymentRemoteDatasource(ref.read(httpClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.read(paymentDatasourceProvider));
});

final processPaymentUseCaseProvider = Provider<ProcessPaymentUseCase>((ref) {
  return ProcessPaymentUseCase(ref.read(paymentRepositoryProvider));
});
