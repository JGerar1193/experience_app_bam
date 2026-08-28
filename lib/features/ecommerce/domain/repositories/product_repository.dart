import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getRecommendedProducts();
  Future<List<Product>> getSummerProducts();
  Future<List<Product>> getAllProducts();
  /// Stream en tiempo real: emite una nueva lista ante cualquier cambio.
  Stream<List<Product>> watchAllProducts();
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
}