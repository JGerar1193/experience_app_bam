import 'package:freezed_annotation/freezed_annotation.dart';

import 'product.dart';

part 'cart_item.freezed.dart';

@freezed
class CartItem with _$CartItem {
  // Constructor privado necesario para poder definir getters/métodos
  const CartItem._();

  const factory CartItem({
    required Product product,
    required int quantity,
    required String selectedSize,
    required String selectedColor,
  }) = _CartItem;

  // Getter personalizado — requiere el constructor privado de arriba
  double get totalPrice => product.price * quantity;
}
