/// Resultado de llamar al endpoint POST /processPayment.
class PaymentResponse {
  final bool success;

  /// "approved" | "declined" | "insufficient_funds"
  final String status;

  /// Presente solo cuando el pago es aprobado
  final String? transactionId;

  final double amount;
  final String currency;
  final String cardLast4;
  final String message;
  final DateTime timestamp;

  const PaymentResponse({
    required this.success,
    required this.status,
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.cardLast4,
    required this.message,
    required this.timestamp,
  });

  bool get isApproved => status == 'approved';
  bool get isDeclined => status == 'declined';
  bool get isInsufficientFunds => status == 'insufficient_funds';
}
