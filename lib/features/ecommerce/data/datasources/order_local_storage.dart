import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/order.dart';
import '../models/order_model.dart';

class OrderLocalStorage {
  final SharedPreferences _prefs;

  // Clave con la que se guardan las órdenes en SharedPreferences
  static const _ordersKey = 'orders';

  OrderLocalStorage(this._prefs);

  // Lee todas las órdenes guardadas
  List<Order> loadOrders() {
    final jsonString = _prefs.getString(_ordersKey);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = json.decode(jsonString) as List;
    return jsonList
        .map<Order>((e) => OrderModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  // Persiste una nueva orden junto a las existentes
  Future<void> saveOrder(Order order) async {
    final existing = loadOrders();
    final updated = [...existing, order];
    final jsonList =
        updated.map((o) => OrderModel.fromEntity(o).toJson()).toList();
    await _prefs.setString(_ordersKey, json.encode(jsonList));
  }
}
