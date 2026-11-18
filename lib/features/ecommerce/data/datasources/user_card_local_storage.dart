import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/payment_card.dart';
import '../models/payment_card_model.dart';

/// Persiste solo las tarjetas agregadas por el usuario (no las del mock).
/// Nunca guarda el número completo: solo BIN (6 primeros) y últimos 4 dígitos.
class UserCardLocalStorage {
  final SharedPreferences _prefs;

  static const _userCardsKey = 'user_cards';

  UserCardLocalStorage(this._prefs);

  // Lee las tarjetas guardadas por el usuario y reescribe el almacenamiento
  // para borrar números completos guardados por versiones anteriores.
  List<PaymentCard> loadUserCards() {
    final jsonString = _prefs.getString(_userCardsKey);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString) as List;
    final cards = jsonList
        .map((e) =>
            PaymentCardModel.fromJson(e as Map<String, dynamic>).toEntity())
        .map(maskPaymentCard)
        .toList();

    _prefs.setString(_userCardsKey, _encode(cards));
    return cards;
  }

  // Guarda la lista completa de tarjetas del usuario, ya enmascaradas
  Future<void> saveUserCards(List<PaymentCard> cards) async {
    await _prefs.setString(_userCardsKey, _encode(cards.map(maskPaymentCard).toList()));
  }

  String _encode(List<PaymentCard> cards) {
    final jsonList =
        cards.map((c) => PaymentCardModel.fromEntity(c).toJson()).toList();
    return json.encode(jsonList);
  }
}

/// Deja solo BIN (6 primeros) y últimos 4 dígitos; el resto se oculta.
PaymentCard maskPaymentCard(PaymentCard card) {
  final digits = card.number.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 12) return card;
  final masked =
      '${digits.substring(0, 6)}${'*' * (digits.length - 10)}${digits.substring(digits.length - 4)}';
  return PaymentCard(
    number: masked,
    holderName: card.holderName,
    network: card.network,
    behavior: card.behavior,
    balanceUsd: card.balanceUsd,
    declineReason: card.declineReason,
  );
}

