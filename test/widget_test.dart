import 'package:flutter_test/flutter_test.dart';

import 'package:experience_app/features/ecommerce/data/datasources/user_card_local_storage.dart';
import 'package:experience_app/features/ecommerce/domain/entities/card_network.dart';
import 'package:experience_app/features/ecommerce/domain/entities/payment_card.dart';

PaymentCard _card(String number) => PaymentCard(
      number: number,
      holderName: 'Test',
      network: CardNetwork.visa,
      behavior: CardBehavior.approved,
    );

void main() {
  group('maskPaymentCard', () {
    test('keeps BIN and last4 and hides the middle digits', () {
      final masked = maskPaymentCard(_card('4242 4242 4242 4242'));

      expect(masked.number, '424242******4242');
      expect(masked.last4, '4242');
    });

    test('returns the card unchanged when it has fewer than 12 digits', () {
      final card = _card('4242 42');

      expect(identical(maskPaymentCard(card), card), isTrue);
    });
  });
}
