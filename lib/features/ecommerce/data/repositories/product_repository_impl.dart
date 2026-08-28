import 'package:experience_app/features/ecommerce/data/datasources/product_firestore_datasource.dart';
import 'package:experience_app/features/ecommerce/data/models/product_model.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductFirestoreDatasource _datasource;

  ProductRepositoryImpl(this._datasource);

  @override
  Future<List<Product>> getRecommendedProducts() async {
    final models = await _datasource.getRecommendedProducts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Product>> getSummerProducts() async {
    final models = await _datasource.getSummerProducts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Product>> getAllProducts() async {
    final models = await _datasource.getAllProducts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<Product>> watchAllProducts() {
    return _datasource
        .watchAllProducts()
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<void> addProduct(Product product) async {
    await _datasource.addProduct(ProductModel.fromEntity(product));
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _datasource.updateProduct(ProductModel.fromEntity(product));
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _datasource.deleteProduct(id);
  }
}
