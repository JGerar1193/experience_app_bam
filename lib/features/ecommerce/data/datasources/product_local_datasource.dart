import 'package:experience_app/features/ecommerce/data/models/product_model.dart';

class ProductLocalDatasource {
  List<ProductModel> getRecommendedProducts() {
    return const [
      ProductModel(
        id: '1',
        name: 'T-shirt Black',
        category: 'Black / M',
        price: 12.99,
        imagePath: 'assets/recomendados/recomendado1.jpg',
        description: 'T-shirt cómoda',
        sizes: ['XS', 'S', 'M', 'L', 'XL'],
        colors: ['black', 'blue', 'grey', 'white'],
      ),
      ProductModel(
        id: '2',
        name: 'T-shirt Grey',
        category: 'Grey / 32',
        price: 12.99,
        imagePath: 'assets/recomendados/recomendado2.jpg',
        description: 'T-shirt cómoda y moderna',
        sizes: ['XS', 'S', 'M', 'L', 'XL'],
        colors: ['black', 'blue', 'grey', 'white'],
      ),
      ProductModel(
        id: '3',
        name: 'Pantalon',
        category: 'Blue / 35',
        price: 38.99,
        imagePath: 'assets/recomendados/recomendado3.jpg',
        description: 'Pantalon cómodo y moderno.',
        sizes: ['XS', 'S', 'M', 'L', 'XL'],
        colors: ['black', 'blue', 'grey', 'white'],
      ),
    ];
  }

  List<ProductModel> getSummerProducts() {
    return const [
      ProductModel(
        id: '4',
        name: 'Bolsa de Verano',
        category: 'Gold / L',
        price: 32.49,
        imagePath: 'assets/verano/sol1.jpg',
        description: 'Bolsa cómoda y moderna.',
        sizes: ['XS', 'S', 'M', 'L', 'XL'],
        colors: ['black', 'blue', 'grey', 'white'],
      ),
      ProductModel(
        id: '5',
        name: 'Pantaloneta de Playa',
        category: 'Orange / M',
        price: 12.99,
        imagePath: 'assets/verano/sol2.jpg',
        description: 'Pantaloneta cómoda y moderna.',
        sizes: ['XS', 'S', 'M', 'L', 'XL'],
        colors: ['black', 'blue', 'grey', 'white'],
      ),
      ProductModel(
        id: '6',
        name: 'Camisa de Playa Amarilla',
        category: 'Yellow / M',
        price: 19.49,
        imagePath: 'assets/verano/sol3.jpg',
        description: 'Camisa cómoda y moderna.',
        sizes: ['XS', 'S', 'M', 'L', 'XL'],
        colors: ['black', 'blue', 'grey', 'white'],
      ),
    ];
  }
}