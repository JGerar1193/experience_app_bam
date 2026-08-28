import '../../domain/entities/card_validation_result.dart';
import '../../domain/entities/payment_card.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/card_local_datasource.dart';

class CardRepositoryImpl implements CardRepository {
  final CardLocalDatasource _datasource;

  CardRepositoryImpl(this._datasource);

  @override
  List<PaymentCard> getTestCards() {
    return _datasource.getTestCards().map((m) => m.toEntity()).toList();
  }

  @override
  CardValidationResult validate(String cardNumber, double amount) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');

    // Busca la tarjeta en el listado de tarjetas de prueba
    final cards = getTestCards();
    final match = _findCard(cards, cleanNumber);

    // Si no está en el listado, se trata como tarjeta genérica aprobada
    if (match == null) {
      return const CardValidationResult(
          status: CardValidationStatus.approved);
    }

    switch (match.behavior) {
      case CardBehavior.alwaysDeclined:
        return CardValidationResult(
          status: CardValidationStatus.declined,
          reason: match.declineReason,
        );
      case CardBehavior.checkFunds:
        final balance = match.balanceUsd ?? 0.0;
        if (amount <= balance) {
          return const CardValidationResult(
              status: CardValidationStatus.approved);
        }
        return const CardValidationResult(
            status: CardValidationStatus.insufficientFunds);
      case CardBehavior.approved:
        return const CardValidationResult(
            status: CardValidationStatus.approved);
    }
  }

  PaymentCard? _findCard(List<PaymentCard> cards, String cleanNumber) {
    try {
      return cards.firstWhere(
        (c) => c.number.replaceAll(RegExp(r'\D'), '') == cleanNumber,
      );
    } catch (_) {
      return null;
    }
  }
}
