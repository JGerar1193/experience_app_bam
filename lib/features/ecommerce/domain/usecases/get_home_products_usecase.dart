import '../entities/product.dart';
import '../repositories/product_repository.dart';

class HomeProducts {
  final List<Product> recommended;
  final List<Product> summer;

  const HomeProducts({
    required this.recommended,
    required this.summer,
  });
}

class GetHomeProductsUseCase {
  final ProductRepository repository;

  const GetHomeProductsUseCase(this.repository);

  Future<HomeProducts> call() async {
    final results = await Future.wait([
      repository.getRecommendedProducts(),
      repository.getSummerProducts(),
    ]);
    return HomeProducts(recommended: results[0], summer: results[1]);
  }

  /// Stream en tiempo real: filtra recommended/summer desde un único listener.
  Stream<HomeProducts> callAsStream() {
    return repository.watchAllProducts().map(
          (products) => HomeProducts(
            recommended: products.where((p) => p.isRecommended).toList(),
            summer: products.where((p) => p.isSummer).toList(),
          ),
        );
  }
}