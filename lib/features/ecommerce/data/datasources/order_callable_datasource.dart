import 'package:cloud_functions/cloud_functions.dart';

import '../../domain/entities/cart_item.dart';

/// Crea la orden y cobra el pago a través de la Cloud Function `create_order`.
/// El precio y el total se calculan en el servidor; el cliente solo envía IDs y cantidades.
class OrderCallableDatasource {
  final FirebaseFunctions _functions;

  OrderCallableDatasource(this._functions);

  Future<String> createOrder({
    required List<CartItem> items,
    required String cardNumber,
  }) async {
    final callable = _functions.httpsCallable('create_order');

    try {
      final result = await callable.call<Map<String, dynamic>>({
        'items': items
            .map(
              (item) => {
                'productId': item.product.id,
                'quantity': item.quantity,
                'selectedSize': item.selectedSize,
                'selectedColor': item.selectedColor,
              },
            )
            .toList(),
        'cardNumber': cardNumber,
      });
      return result.data['orderId'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'No se pudo completar el pago.');
    }
  }
}
