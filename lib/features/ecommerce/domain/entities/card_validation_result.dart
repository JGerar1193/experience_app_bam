enum CardValidationStatus { approved, declined, insufficientFunds }

class CardValidationResult {
  final CardValidationStatus status;

  /// Mensaje de razón (presente si status es [CardValidationStatus.declined]).
  final String? reason;

  const CardValidationResult({required this.status, this.reason});

  bool get isApproved => status == CardValidationStatus.approved;
}
