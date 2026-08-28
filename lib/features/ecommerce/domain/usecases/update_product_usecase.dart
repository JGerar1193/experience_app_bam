import '../entities/product.dart';
import '../repositories/product_repository.dart';

class UpdateProductUseCase {
  final ProductRepository repository;

  const UpdateProductUseCase(this.repository);

  Future<void> call(Product product) => repository.updateProduct(product);
}
