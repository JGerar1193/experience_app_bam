import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_image.dart';
import 'bag_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late String _selectedSize;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.product.sizes.first;
    _selectedColor = widget.product.colors.first;
  }

  Color _colorFromString(String color) {
    switch (color) {
      case 'black':
        return Colors.black;
      case 'blue':
        return AppColors.primary;
      case 'grey':
        return Colors.grey;
      case 'white':
        return const Color(0xFFE0E0E0);
      default:
        return Colors.grey;
    }
  }

  void _addToBag() {
    ref.read(cartProvider.notifier).addItem(
          widget.product,
          _selectedSize,
          _selectedColor,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} añadido a tu bolsa'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Ver bolsa',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BagScreen()),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen + botón cerrar
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          child: ProductImage(
                          imagePath: product.imagePath,
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre + favorito
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.favorite_border,
                                color: AppColors.textGray,
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Precio
                          Text(
                            '\$ ${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Descripción
                          Text(
                            product.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textGray,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Tallas
                          const Text(
                            'Size',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: product.sizes.map((size) {
                              final isSelected = size == _selectedSize;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedSize = size),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    size,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Colores
                          const Text(
                            'Color',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: product.colors.map((color) {
                              final isSelected = color == _selectedColor;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedColor = color),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _colorFromString(color),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón Add to bag
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _addToBag,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add to bag',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
