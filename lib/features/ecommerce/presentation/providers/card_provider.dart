import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/card_local_datasource.dart';
import '../../data/datasources/user_card_local_storage.dart';
import '../../data/repositories/card_repository_impl.dart';
import '../../domain/entities/payment_card.dart';
import '../../domain/repositories/card_repository.dart';
import '../../domain/usecases/get_test_cards_usecase.dart';
import '../../domain/usecases/validate_card_usecase.dart';
import 'cart_provider.dart';

final cardDatasourceProvider = Provider<CardLocalDatasource>((ref) {
  return CardLocalDatasource();
});

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepositoryImpl(ref.read(cardDatasourceProvider));
});

final getTestCardsUseCaseProvider = Provider<GetTestCardsUseCase>((ref) {
  return GetTestCardsUseCase(ref.read(cardRepositoryProvider));
});

final validateCardUseCaseProvider = Provider<ValidateCardUseCase>((ref) {
  return ValidateCardUseCase(ref.read(cardRepositoryProvider));
});

final userCardStorageProvider = Provider<UserCardLocalStorage>((ref) {
  return UserCardLocalStorage(ref.read(sharedPreferencesProvider));
});

// ─── Notifier que gestiona la lista de tarjetas (mock + agregadas por usuario)

class CardNotifier extends StateNotifier<List<PaymentCard>> {
  final UserCardLocalStorage _storage;

  /// Inicializa con las tarjetas del mock más las del usuario guardadas en disco.
  CardNotifier(List<PaymentCard> mockCards, this._storage)
      : super([...mockCards, ..._storage.loadUserCards()]);

  Future<void> addCard(PaymentCard card) async {
    // Determina las tarjetas que el usuario ha agregado (las que no son del mock)
    final userCards = state
        .where((c) => !_isMockCard(c))
        .toList()
      ..add(card);

    state = [...state, card];

    // Persiste solo las tarjetas del usuario
    await _storage.saveUserCards(userCards);
  }

  /// Las tarjetas del mock tienen holderName en mayúsculas fijas.
  bool _isMockCard(PaymentCard card) {
    const mockNumbers = {
      '4000000000000002',
      '4000000000000069',
      '4111111111111111',
      '4242424242424242',
      '5555555555554444',
    };
    return mockNumbers
        .contains(card.number.replaceAll(RegExp(r'\D'), ''));
  }
}

final cardListProvider =
    StateNotifierProvider<CardNotifier, List<PaymentCard>>((ref) {
  final mockCards = ref.read(getTestCardsUseCaseProvider)();
  final storage = ref.read(userCardStorageProvider);
  return CardNotifier(mockCards, storage);
});

// Alias retrocompatible para providers que aún usen testCardsProvider
final testCardsProvider = cardListProvider;
