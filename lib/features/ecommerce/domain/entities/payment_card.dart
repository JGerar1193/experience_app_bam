import 'card_network.dart';

/// Comportamiento simulado de la tarjeta en el mock de pagos.
enum CardBehavior {
  /// Siempre aprobada (tarjeta genérica no listada o con fondos suficientes).
  approved,

  /// Siempre declinada sin importar el monto.
  alwaysDeclined,

  /// El resultado depende del saldo disponible vs. el monto cobrado.
  checkFunds,
}

class PaymentCard {
  final String number;        // Número con espacios: "4242 4242 4242 4242"
  final String holderName;    // Nombre del titular / etiqueta del mock
  final CardNetwork network;
  final CardBehavior behavior;
  final double? balanceUsd;   // Saldo disponible (solo para checkFunds)
  final String? declineReason; // Razón de rechazo (solo para alwaysDeclined)

  const PaymentCard({
    required this.number,
    required this.holderName,
    required this.network,
    required this.behavior,
    this.balanceUsd,
    this.declineReason,
  });

  /// Últimos 4 dígitos del número de tarjeta.
  String get last4 {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
  }

  /// Número enmascarado para mostrar en UI.
  String get maskedNumber => '•••• •••• •••• $last4';
}
