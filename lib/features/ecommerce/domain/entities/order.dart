import 'cart_item.dart';

class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final String paymentMethod;
  final String? selectedCard;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.paymentMethod,
    this.selectedCard,
    required this.createdAt,
  });
}
