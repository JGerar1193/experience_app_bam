import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductFirestoreDatasource {
  final FirebaseFirestore _firestore;
  static const _collection = 'Products';

  ProductFirestoreDatasource(this._firestore);

  Future<List<ProductModel>> getRecommendedProducts() async {
    final snap = await _firestore
        .collection(_collection)
        .where('isRecommended', isEqualTo: true)
        .get();
    return snap.docs
        .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<ProductModel>> getSummerProducts() async {
    final snap = await _firestore
        .collection(_collection)
        .where('isSummer', isEqualTo: true)
        .get();
    return snap.docs
        .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<ProductModel>> getAllProducts() async {
    final snap = await _firestore.collection(_collection).get();
    return snap.docs
        .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Stream en tiempo real de todos los productos.
  /// Emite una nueva lista cada vez que Firestore detecta un cambio.
  Stream<List<ProductModel>> watchAllProducts() {
    return _firestore.collection(_collection).snapshots().map(
          (snap) => snap.docs
              .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addProduct(ProductModel product) async {
    await _firestore.collection(_collection).add(product.toFirestore());
  }

  Future<void> updateProduct(ProductModel product) async {
    await _firestore
        .collection(_collection)
        .doc(product.id)
        .update(product.toFirestore());
  }

  Future<void> deleteProduct(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
