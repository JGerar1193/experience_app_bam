import '../entities/cart_item.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  /// Crea la orden y cobra el pago en el servidor; retorna la orden creada.
  Future<Order> placeOrder({
    required List<CartItem> items,
    required String cardNumber,
  });


  /// Stream en tiempo real de las órdenes del usuario autenticado
  Stream<List<Order>> watchUserOrders(String uid);
}
