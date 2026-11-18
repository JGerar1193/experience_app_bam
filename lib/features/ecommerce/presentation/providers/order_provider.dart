import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/order_callable_datasource.dart';
import '../../data/datasources/order_firestore_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/place_order_usecase.dart';
import '../providers/ecommerce_provider.dart';

final orderFirestoreDatasourceProvider = Provider<OrderFirestoreDatasource>((
  ref,
) {
  return OrderFirestoreDatasource(ref.read(firestoreProvider));
});

final orderCallableDatasourceProvider = Provider<OrderCallableDatasource>((
  ref,
) {
  return OrderCallableDatasource(FirebaseFunctions.instance);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(
    ref.read(orderCallableDatasourceProvider),
    ref.read(orderFirestoreDatasourceProvider),
  );
});


final orderByIdProvider = FutureProvider.autoDispose.family<Order?, String>((
  ref,
  orderId,
) async {
  final datasource = ref.read(orderFirestoreDatasourceProvider);
  final model = await datasource.fetchOrderById(orderId);
  return model?.toEntity();
});

final placeOrderUseCaseProvider = Provider<PlaceOrderUseCase>((ref) {
  return PlaceOrderUseCase(ref.read(orderRepositoryProvider));
});

// Stream en tiempo real de las órdenes del usuario autenticado.
// autoDispose garantiza que se destruya al cerrar sesión y se recree
// con el UID correcto cuando un nuevo usuario inicia sesión.
final orderProvider =
    StreamNotifierProvider.autoDispose<OrderNotifier, List<Order>>(
      OrderNotifier.new,
    );

class OrderNotifier extends AutoDisposeStreamNotifier<List<Order>> {
  @override
  Stream<List<Order>> build() {
    // Observa authProvider: si el usuario cambia, este build() se re-ejecuta.
    final authUser = ref.watch(authProvider).user;
    if (authUser == null) return const Stream.empty();

    final uid = fb.FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const Stream.empty();

    return ref.watch(orderRepositoryProvider).watchUserOrders(uid);
  }

  Future<Order> placeOrder({
    required List<CartItem> items,
    required String cardNumber,
  }) async {
    return ref.read(placeOrderUseCaseProvider)(
      items: items,
      cardNumber: cardNumber,
    );
  }
}
