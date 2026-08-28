import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/payment_response_model.dart';

class PaymentRemoteDatasource {
  final http.Client _client;

  static const _processPaymentUrl =
      'https://processpayment-sfdkfoab2q-uc.a.run.app';

  PaymentRemoteDatasource(this._client);

  /// Llama al endpoint POST /processPayment y retorna el modelo de respuesta.
  /// Lanza una [PaymentApiException] ante errores HTTP 4xx/5xx.
  Future<PaymentResponseModel> processPayment({
    required String cardNumber,
    required double amount,
    required String currency,
  }) async {
    final body = json.encode({
      'cardNumber': cardNumber.replaceAll(RegExp(r'\D'), ''),
      'amount': amount,
      'currency': currency,
    });

    final response = await _client.post(
      Uri.parse(_processPaymentUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonMap =
          json.decode(response.body) as Map<String, dynamic>;
      return PaymentResponseModel.fromJson(jsonMap);
    }

    if (response.statusCode == 400) {
      throw PaymentApiException(
          'Invalid request: missing amount or cardNumber (400)');
    }

    throw PaymentApiException(
        'Unexpected error from payment service (${response.statusCode})');
  }
}

/// Excepción específica para errores del servicio de pagos.
class PaymentApiException implements Exception {
  final String message;
  PaymentApiException(this.message);

  @override
  String toString() => 'PaymentApiException: $message';
}
