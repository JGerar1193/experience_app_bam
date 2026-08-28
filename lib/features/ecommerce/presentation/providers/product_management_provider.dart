import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../../domain/usecases/add_product_usecase.dart';
import '../../domain/usecases/delete_product_usecase.dart';
import '../../domain/usecases/update_product_usecase.dart';
import 'ecommerce_provider.dart';

// ---------- Use case providers ----------

final addProductUseCaseProvider = Provider<AddProductUseCase>((ref) {
  return AddProductUseCase(ref.watch(productRepositoryProvider));
});

final updateProductUseCaseProvider = Provider<UpdateProductUseCase>((ref) {
  return UpdateProductUseCase(ref.watch(productRepositoryProvider));
});

final deleteProductUseCaseProvider = Provider<DeleteProductUseCase>((ref) {
  return DeleteProductUseCase(ref.watch(productRepositoryProvider));
});

// ---------- State ----------

/// Lista en tiempo real de todos los productos.
/// Usa StreamNotifierProvider para recibir cambios de Firestore automáticamente.
final allProductsProvider =
    StreamNotifierProvider<AllProductsNotifier, List<Product>>(
  AllProductsNotifier.new,
);

class AllProductsNotifier extends StreamNotifier<List<Product>> {
  @override
  Stream<List<Product>> build() {
    return ref.watch(productRepositoryProvider).watchAllProducts();
  }

  /// Agrega un producto. Firestore notifica el stream automáticamente.
  Future<void> addProduct(Product product) async {
    await ref.read(addProductUseCaseProvider).call(product);
  }

  /// Actualiza un producto. Firestore notifica el stream automáticamente.
  Future<void> updateProduct(Product product) async {
    await ref.read(updateProductUseCaseProvider).call(product);
  }

  /// Elimina un producto. Firestore notifica el stream automáticamente.
  Future<void> deleteProduct(String id) async {
    await ref.read(deleteProductUseCaseProvider).call(id);
  }
}
