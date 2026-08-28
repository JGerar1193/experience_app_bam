import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/cart_local_storage.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';

// Provider de SharedPreferences — se sobreescribe en main.dart con el valor real
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Debe inicializarse en main.dart');
});

// Provider del storage del carrito
final cartStorageProvider = Provider<CartLocalStorage>((ref) {
  return CartLocalStorage(ref.read(sharedPreferencesProvider));
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  final CartLocalStorage _storage;

  // Al inicializar carga el carrito guardado desde SharedPreferences
  CartNotifier(this._storage) : super(_storage.loadCart());

  // Guarda el estado actual en SharedPreferences después de cada cambio
  void _persist() => _storage.saveCart(state);

  void addItem(Product product, String size, String color) {
    final existingIndex = state.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedSize == size &&
          item.selectedColor == color,
    );

    if (existingIndex >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      state = [
        ...state,
        CartItem(
          product: product,
          quantity: 1,
          selectedSize: size,
          selectedColor: color,
        ),
      ];
    }
    _persist();
  }

  void increment(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index)
          state[i].copyWith(quantity: state[i].quantity + 1)
        else
          state[i],
    ];
    _persist();
  }

  void decrement(int index) {
    if (state[index].quantity <= 1) {
      remove(index);
      return;
    }
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index)
          state[i].copyWith(quantity: state[i].quantity - 1)
        else
          state[i],
    ];
    _persist();
  }

  void remove(int index) {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != index) state[i],
    ];
    _persist();
  }

  // Vacía completamente el carrito y persiste el estado
  void clearAll() {
    state = [];
    _persist();
  }

  double get total =>
      state.fold(0.0, (sum, item) => sum + item.totalPrice);
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>(
  (ref) => CartNotifier(ref.read(cartStorageProvider)),
);
