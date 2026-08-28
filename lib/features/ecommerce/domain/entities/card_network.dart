enum CardNetwork { visa, mastercard, americanExpress, discover, dinersClub, unknown }

extension CardNetworkX on CardNetwork {
  String get displayName {
    switch (this) {
      case CardNetwork.visa:
        return 'Visa';
      case CardNetwork.mastercard:
        return 'Mastercard';
      case CardNetwork.americanExpress:
        return 'Amex';
      case CardNetwork.discover:
        return 'Discover';
      case CardNetwork.dinersClub:
        return 'Diners Club';
      case CardNetwork.unknown:
        return 'Card';
    }
  }
}

/// Detecta la red de una tarjeta a partir de su número (BIN).
/// Función pura: no tiene dependencias externas.
CardNetwork detectCardNetwork(String rawNumber) {
  final number = rawNumber.replaceAll(RegExp(r'\D'), '');
  if (number.isEmpty) return CardNetwork.unknown;

  // Visa: empieza con 4
  if (number.startsWith('4')) return CardNetwork.visa;

  // Mastercard: prefijo 51-55 ó 2221-2720
  if (number.length >= 2) {
    final p2 = int.parse(number.substring(0, 2));
    if (p2 >= 51 && p2 <= 55) return CardNetwork.mastercard;
  }
  if (number.length >= 4) {
    final p4 = int.parse(number.substring(0, 4));
    if (p4 >= 2221 && p4 <= 2720) return CardNetwork.mastercard;
  }

  // American Express: empieza con 34 ó 37
  if (number.startsWith('34') || number.startsWith('37')) {
    return CardNetwork.americanExpress;
  }

  // Discover: 6011, 622126-622925, 644-649, 65
  if (number.startsWith('6011') || number.startsWith('65')) {
    return CardNetwork.discover;
  }
  if (number.length >= 6) {
    final p6 = int.parse(number.substring(0, 6));
    if (p6 >= 622126 && p6 <= 622925) return CardNetwork.discover;
  }
  if (number.length >= 3) {
    final p3 = int.parse(number.substring(0, 3));
    if (p3 >= 644 && p3 <= 649) return CardNetwork.discover;
  }

  // Diners Club: 300-305, 36, 38
  if (number.length >= 3) {
    final p3 = int.parse(number.substring(0, 3));
    if (p3 >= 300 && p3 <= 305) return CardNetwork.dinersClub;
  }
  if (number.startsWith('36') || number.startsWith('38')) {
    return CardNetwork.dinersClub;
  }

  return CardNetwork.unknown;
}
