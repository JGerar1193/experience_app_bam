import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../models/order_model.dart';

class OrderFirestoreDatasource {
  final FirebaseFirestore _firestore;
  static const _collection = 'orders';

  OrderFirestoreDatasource(this._firestore);

  /// Genera una referencia de documento con ID único (sin guardar aún).
  DocumentReference<Map<String, dynamic>> newDocRef() {
    return _firestore.collection(_collection).doc();
  }

  /// Guarda la orden usando la referencia pre-generada (para conocer el ID antes de guardar).
  Future<void> saveOrder(
    OrderModel order,
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    await docRef.set(order.toFirestore());
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
