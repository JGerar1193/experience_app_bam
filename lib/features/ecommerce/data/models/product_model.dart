import 'package:experience_app/features/ecommerce/domain/entities/product.dart';

class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final String imagePath;
  final String description;
  final List<String> sizes;
  final List<String> colors;
  final bool isRecommended;
  final bool isSummer;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imagePath,
    required this.description,
    required this.sizes,
    required this.colors,
    this.isRecommended = false,
    this.isSummer = false,
  });

  // Convierte un Map (JSON) a ProductModel
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      imagePath: json['imagePath'] as String,
      description: json['description'] as String,
      sizes: List<String>.from(json['sizes'] as List),
      colors: List<String>.from(json['colors'] as List),
      isRecommended: json['isRecommended'] as bool? ?? false,
      isSummer: json['isSummer'] as bool? ?? false,
    );
  }

  // Convierte un documento de Firestore a ProductModel (el id viene del doc.id)
  factory ProductModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return ProductModel(
      id: docId,
      name: data['name'] as String,
      // Firestore acepta tanto 'category' como 'Category'
      category: (data['category'] ?? data['Category']) as String,
      // Firestore acepta tanto 'price' como 'Price'
      price: ((data['price'] ?? data['Price']) as num).toDouble(),
      imagePath: data['imagePath'] as String,
      description: data['description'] as String,
      sizes: List<String>.from(data['sizes'] as List),
      colors: List<String>.from(data['colors'] as List),
      isRecommended: data['isRecommended'] as bool? ?? false,
      isSummer: data['isSummer'] as bool? ?? false,
    );
  }

  // Convierte ProductModel a Map para guardar en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'imagePath': imagePath,
      'description': description,
      'sizes': sizes,
      'colors': colors,
      'isRecommended': isRecommended,
      'isSummer': isSummer,
    };
  }

  // Convierte ProductModel a Map para guardar en Firestore (sin el id, ese va en el doc.id)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'imagePath': imagePath,
      'description': description,
      'sizes': sizes,
      'colors': colors,
      'isRecommended': isRecommended,
      'isSummer': isSummer,
    };
  }

  // Convierte ProductModel a la entidad del dominio
  Product toEntity() {
    return Product(
      id: id,
      name: name,
      category: category,
      price: price,
      imagePath: imagePath,
      description: description,
      sizes: sizes,
      colors: colors,
      isRecommended: isRecommended,
      isSummer: isSummer,
    );
  }

  // Crea un ProductModel desde la entidad del dominio
  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      name: product.name,
      category: product.category,
      price: product.price,
      imagePath: product.imagePath,
      description: product.description,
      sizes: product.sizes,
      colors: product.colors,
      isRecommended: product.isRecommended,
      isSummer: product.isSummer,
    );
  }
}