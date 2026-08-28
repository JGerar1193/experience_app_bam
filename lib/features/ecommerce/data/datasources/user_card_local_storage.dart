import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/payment_card.dart';
import '../models/payment_card_model.dart';

/// Persiste solo las tarjetas agregadas por el usuario (no las del mock).
class UserCardLocalStorage {
  final SharedPreferences _prefs;

  static const _userCardsKey = 'user_cards';

  UserCardLocalStorage(this._prefs);

  // Lee las tarjetas guardadas por el usuario
  List<PaymentCard> loadUserCards() {
    final jsonString = _prefs.getString(_userCardsKey);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString) as List;
    return jsonList
        .map((e) =>
            PaymentCardModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  // Guarda la lista completa de tarjetas del usuario
  Future<void> saveUserCards(List<PaymentCard> cards) async {
    final jsonList =
        cards.map((c) => PaymentCardModel.fromEntity(c).toJson()).toList();
    await _prefs.setString(_userCardsKey, json.encode(jsonList));
  }
}
