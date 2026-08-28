import 'package:flutter/material.dart';

import 'product_image_placeholder.dart';

/// Widget que carga imagen desde asset o URL de Firebase Storage.
/// En web usa <img> HTML para evitar bloqueos CORS con fetch().
class ProductImage extends StatelessWidget {
  final String imagePath;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double placeholderBorderRadius;

  const ProductImage({
    super.key,
    required this.imagePath,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.placeholderBorderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image(
        image: NetworkImage(
          imagePath,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        ),
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, _, _) => ProductImagePlaceholder(
          height: height ?? 100,
          width: width ?? 100,
          borderRadius: placeholderBorderRadius,
        ),
      );
    }
    return Image.asset(
      imagePath,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (_, _, _) => ProductImagePlaceholder(
        height: height ?? 100,
        width: width ?? 100,
        borderRadius: placeholderBorderRadius,
      ),
    );
  }
}
