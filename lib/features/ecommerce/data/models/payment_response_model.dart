import '../../domain/entities/payment_response.dart';

class PaymentResponseModel {
  final bool success;
  final String status;
  final String? transactionId;
  final double amount;
  final String currency;
  final String cardLast4;
  final String message;
  final DateTime timestamp;

  const PaymentResponseModel({
    required this.success,
    required this.status,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.cardLast4,
    required this.message,
    required this.timestamp,
  });

  // Convierte el JSON de la respuesta de la API a PaymentResponseModel
  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      success: json['success'] as bool,
      status: json['status'] as String,
      transactionId: json['transactionId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      cardLast4: json['cardLast4'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  // Convierte PaymentResponseModel a la entidad del dominio
  PaymentResponse toEntity() {
    return PaymentResponse(
      success: success,
      status: status,
      transactionId: transactionId,
      amount: amount,
      currency: currency,
      cardLast4: cardLast4,
      message: message,
      timestamp: timestamp,
    );
  }
}
