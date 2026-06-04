import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/cart_repository.dart';

class CartNotifier extends AsyncNotifier<List<CartItemWithProduct>> {
  late CartRepository _repository;

  @override
  FutureOr<List<CartItemWithProduct>> build() {
    _repository = ref.watch(cartRepositoryProvider);
    return _repository.getCart();
  }

  Future<void> addItem(String variantId, int quantity) async {
    state = const AsyncValue.loading();
    try {
      await _repository.addToCart(variantId, quantity);
      final newCart = await _repository.getCart();
      state = AsyncValue.data(newCart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    
    // Optimistic UI update
    final currentList = state.value;
    if (currentList != null) {
      final updatedList = currentList.map((item) {
        if (item.id == cartItemId) {
          return CartItemWithProduct(
            id: item.id,
            variantId: item.variantId,
            productId: item.productId,
            quantity: quantity,
            productName: item.productName,
            price: item.price,
            color: item.color,
            size: item.size,
            imageUrl: item.imageUrl,
          );
        }
        return item;
      }).toList();
      state = AsyncValue.data(updatedList);
    }

    try {
      await _repository.updateQuantity(cartItemId, quantity);
      final newCart = await _repository.getCart();
      state = AsyncValue.data(newCart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeItem(String cartItemId) async {
    // Optimistic UI update
    final currentList = state.value;
    if (currentList != null) {
      final updatedList = currentList.where((item) => item.id != cartItemId).toList();
      state = AsyncValue.data(updatedList);
    }

    try {
      await _repository.removeFromCart(cartItemId);
      final newCart = await _repository.getCart();
      state = AsyncValue.data(newCart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearCart() async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearCart();
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  double get subtotal {
    final list = state.value ?? [];
    return list.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get finalAmount {
    // Extendable for coupons, taxes, shipping
    return subtotal;
  }
}

final cartProvider = AsyncNotifierProvider<CartNotifier, List<CartItemWithProduct>>(() {
  return CartNotifier();
});
