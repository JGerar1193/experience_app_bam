import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import '../screens/product_detail_screen.dart';
import 'product_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
      width: 145,
      margin: const EdgeInsets.only(right: 12),

      // Forma de la tarjeta
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen superior del producto
          // const ProductImagePlaceholder(
          //   height: 110,
          //   width: double.infinity,
          //   borderRadius: 14,
          // ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ProductImage(
              imagePath: product.imagePath,
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholderBorderRadius: 14,
            ),
          ),
          const SizedBox(height: 10),

          // Nombre del producto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Precio del producto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '\$ ${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ));
  }
}