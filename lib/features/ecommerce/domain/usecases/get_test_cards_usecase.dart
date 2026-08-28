import '../entities/payment_card.dart';
import '../repositories/card_repository.dart';

class GetTestCardsUseCase {
  final CardRepository repository;

  const GetTestCardsUseCase(this.repository);

  List<PaymentCard> call() => repository.getTestCards();
}
