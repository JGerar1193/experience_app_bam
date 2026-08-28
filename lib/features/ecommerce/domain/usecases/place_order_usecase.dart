import '../entities/cart_item.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class PlaceOrderUseCase {
  final OrderRepository repository;

  const PlaceOrderUseCase(this.repository);

  Future<Order> call({
    required List<CartItem> items,
    required double total,
    required String paymentMethod,
    String? selectedCard,
  }) {
    return repository.placeOrder(
      items: items,
      total: total,
      paymentMethod: paymentMethod,
      selectedCard: selectedCard,
    );
  }
}
