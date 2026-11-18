import '../../domain/repositories/order_repository.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../datasources/order_callable_datasource.dart';
import '../datasources/order_firestore_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderCallableDatasource _callable;
  final OrderFirestoreDatasource _firestore;

  OrderRepositoryImpl(this._callable, this._firestore);

  @override
  Future<Order> placeOrder({
    required List<CartItem> items,
    required String cardNumber,
  }) async {
    final orderId = await _callable.createOrder(
      items: items,
      cardNumber: cardNumber,
    );
    final model = await _firestore.fetchOrderById(orderId);
    if (model == null) {
      throw Exception('La orden se creó pero no se pudo leer.');
    }
    return model.toEntity();
  }

  @override
  Stream<List<Order>> watchUserOrders(String uid) {
    return _firestore
        .watchUserOrders(uid)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }
}


