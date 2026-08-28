import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String category,
    required double price,
    required String imagePath,
    required String description,
    required List<String> sizes,
    required List<String> colors,
    @Default(false) bool isRecommended,
    @Default(false) bool isSummer,
  }) = _Product;
}