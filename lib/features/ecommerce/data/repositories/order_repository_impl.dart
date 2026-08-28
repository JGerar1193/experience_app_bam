import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_firestore_datasource.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderFirestoreDatasource _datasource;

  OrderRepositoryImpl(this._datasource);

  @override
  Future<Order> placeOrder({
    required List<CartItem> items,
    required double total,
    required String paymentMethod,
    String? selectedCard,
  }) async {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid ?? '';
    final docRef = _datasource.newDocRef();

    final order = Order(
      id: docRef.id,
      userId: uid,
      items: List.unmodifiable(items),
      total: total,
      paymentMethod: paymentMethod,
      selectedCard: selectedCard,
      createdAt: DateTime.now(),
    );

    await _datasource.saveOrder(OrderModel.fromEntity(order), docRef);
    return order;
  }

  @override
  Stream<List<Order>> watchUserOrders(String uid) {
    return _datasource
        .watchUserOrders(uid)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}

