import '../models/payment_card_model.dart';

/// Fuente de datos local con las tarjetas de prueba del mock.
/// Los datos reflejan exactamente la documentación de tarjetas de prueba.
class CardLocalDatasource {
  List<PaymentCardModel> getTestCards() {
    return const [
      // ── Siempre declinadas ─────────────────────────────────────────────
      PaymentCardModel(
        number: '4000 0000 0000 0002',
        holderName: 'DECLINED CARD',
        behavior: 'always_declined',
        declineReason: 'Do not honor – bloqueada por emisor',
      ),
      PaymentCardModel(
        number: '4000 0000 0000 0069',
        holderName: 'EXPIRED CARD',
        behavior: 'always_declined',
        declineReason: 'Tarjeta expirada',
      ),

      // ── Dependen del saldo (check_funds) ──────────────────────────────
      PaymentCardModel(
        number: '4111 1111 1111 1111',
        holderName: 'LOW FUNDS CARD',
        behavior: 'check_funds',
        balanceUsd: 50.0,
      ),
      PaymentCardModel(
        number: '4242 4242 4242 4242',
        holderName: 'MID FUNDS CARD',
        behavior: 'check_funds',
        balanceUsd: 300.0,
      ),
      PaymentCardModel(
        number: '5555 5555 5555 4444',
        holderName: 'HIGH FUNDS CARD',
        behavior: 'check_funds',
        balanceUsd: 1000.0,
      ),
    ];
  }
}
