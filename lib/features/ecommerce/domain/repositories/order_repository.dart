import '../entities/cart_item.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  /// Crea y persiste una nueva orden en Firestore, retorna la orden creada
  Future<Order> placeOrder({
    required List<CartItem> items,
    required double total,
    required String paymentMethod,
    String? selectedCard,
  });

  /// Stream en tiempo real de las órdenes del usuario autenticado
  Stream<List<Order>> watchUserOrders(String uid);
}
