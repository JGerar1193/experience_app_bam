import 'package:experience_app/features/ecommerce/domain/entities/cart_item.dart';

import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  final int quantity;
  final String selectedSize;
  final String selectedColor;

  const CartItemModel({
    required this.product,
    required this.quantity,
    required this.selectedSize,
    required this.selectedColor,
  });

  // Convierte un Map (JSON) a CartItemModel
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      selectedSize: json['selectedSize'] as String,
      selectedColor: json['selectedColor'] as String,
    );
  }

  // Convierte CartItemModel a Map para guardar en JSON
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
    };
  }

  // Convierte CartItemModel a la entidad del dominio
  CartItem toEntity() {
    return CartItem(
      product: product.toEntity(),
      quantity: quantity,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
    );
  }

  // Crea un CartItemModel desde la entidad del dominio
  factory CartItemModel.fromEntity(CartItem item) {
    return CartItemModel(
      product: ProductModel.fromEntity(item.product),
      quantity: item.quantity,
      selectedSize: item.selectedSize,
      selectedColor: item.selectedColor,
    );
  }
}
