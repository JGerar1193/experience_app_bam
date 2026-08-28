import '../../domain/entities/card_network.dart';
import '../../domain/entities/payment_card.dart';

class PaymentCardModel {
  final String number;
  final String holderName;
  final String behavior; // 'approved' | 'always_declined' | 'check_funds'
  final double? balanceUsd;
  final String? declineReason;

  const PaymentCardModel({
    required this.number,
    required this.holderName,
    required this.behavior,
    this.balanceUsd,
    this.declineReason,
  });

  // Convierte un Map (JSON) a PaymentCardModel
  factory PaymentCardModel.fromJson(Map<String, dynamic> json) {
    return PaymentCardModel(
      number: json['number'] as String,
      holderName: json['holderName'] as String,
      behavior: json['behavior'] as String,
      balanceUsd: (json['balanceUsd'] as num?)?.toDouble(),
      declineReason: json['declineReason'] as String?,
    );
  }

  // Convierte PaymentCardModel a Map
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'holderName': holderName,
      'behavior': behavior,
      if (balanceUsd != null) 'balanceUsd': balanceUsd,
      if (declineReason != null) 'declineReason': declineReason,
    };
  }

  // Convierte PaymentCardModel a la entidad del dominio
  PaymentCard toEntity() {
    return PaymentCard(
      number: number,
      holderName: holderName,
      network: detectCardNetwork(number),
      behavior: _parseBehavior(behavior),
      balanceUsd: balanceUsd,
      declineReason: declineReason,
    );
  }

  // Crea un PaymentCardModel desde la entidad del dominio
  factory PaymentCardModel.fromEntity(PaymentCard card) {
    return PaymentCardModel(
      number: card.number,
      holderName: card.holderName,
      behavior: _behaviorToString(card.behavior),
      balanceUsd: card.balanceUsd,
      declineReason: card.declineReason,
    );
  }

  static CardBehavior _parseBehavior(String value) {
    switch (value) {
      case 'always_declined':
        return CardBehavior.alwaysDeclined;
      case 'check_funds':
        return CardBehavior.checkFunds;
      default:
        return CardBehavior.approved;
    }
  }

  static String _behaviorToString(CardBehavior behavior) {
    switch (behavior) {
      case CardBehavior.alwaysDeclined:
        return 'always_declined';
      case CardBehavior.checkFunds:
        return 'check_funds';
      case CardBehavior.approved:
        return 'approved';
    }
  }
}
