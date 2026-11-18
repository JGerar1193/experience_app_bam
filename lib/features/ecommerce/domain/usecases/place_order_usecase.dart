import '../entities/cart_item.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class PlaceOrderUseCase {
  final OrderRepository repository;

  const PlaceOrderUseCase(this.repository);

  Future<Order> call({
    required List<CartItem> items,
    required String cardNumber,
  }) {
    return repository.placeOrder(items: items, cardNumber: cardNumber);
  }
}
