import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/order_model.dart';

class OrderFirestoreDatasource {
  final FirebaseFirestore _firestore;
  static const _collection = 'orders';

  OrderFirestoreDatasource(this._firestore);

  /// Obtiene una sola orden por su ID de documento.
  Future<OrderModel?> fetchOrderById(String orderId) async {
    final doc = await _firestore.collection(_collection).doc(orderId).get();
    if (!doc.exists || doc.data() == null) return null;
    return OrderModel.fromFirestore(doc.data()!, doc.id);
  }

  /// Stream en tiempo real de órdenes de un usuario, ordenadas de más reciente a más antigua.
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }
}
