import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/order.dart';
import '../providers/order_provider.dart';
import '../widgets/product_image.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Mis Transacciones',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error al cargar transacciones: $e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return const _EmptyOrders();
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _OrderCard(order: orders[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No tienes compras aún',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          const SizedBox(height: 6),
          Text('Tus órdenes aparecerán aquí',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// ─── Tarjeta de orden ─────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy  HH:mm', 'es');
    final shortId = order.id.length > 8
        ? '#${order.id.substring(0, 8).toUpperCase()}'
        : '#${order.id.toUpperCase()}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(shortId,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A7CFF)),
                ),
              ],
            ),
          ),

          // ── Fecha y método de pago ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(dateFormat.format(order.createdAt),
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
                const Spacer(),
                Icon(Icons.credit_card_outlined,
                    size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(order.paymentMethod,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),

          const Divider(height: 20),

          // ── Items ──────────────────────────────────────────────────────
          ...order.items.map(
            (item) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Imagen del producto
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ProductImage(
                      imagePath: item.product.imagePath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholderBorderRadius: 6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(
                          '${item.selectedSize} · ${item.selectedColor}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('x${item.quantity}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      Text(
                        '\$${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _imageFallback() => Container(
        width: 44,
        height: 44,
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported,
            color: Colors.grey, size: 20),
      );
}
