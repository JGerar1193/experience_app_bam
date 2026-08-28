import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cart_item.dart';
import '../models/cart_item_model.dart';

class CartLocalStorage {
  final SharedPreferences _prefs;

  // Clave con la que se guarda el carrito en SharedPreferences
  static const _cartKey = 'cart_items';

  CartLocalStorage(this._prefs);

  // Lee el carrito guardado y lo devuelve como lista de entidades
  List<CartItem> loadCart() {
    final jsonString = _prefs.getString(_cartKey);

    // Si no hay nada guardado, retorna carrito vacío
    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString) as List;
    return jsonList
        .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  // Guarda la lista completa del carrito en SharedPreferences
  Future<void> saveCart(List<CartItem> items) async {
    final jsonList = items
        .map((item) => CartItemModel.fromEntity(item).toJson())
        .toList();

    await _prefs.setString(_cartKey, json.encode(jsonList));
  }

  // Limpia el carrito guardado
  Future<void> clearCart() async {
    await _prefs.remove(_cartKey);
  }
}
