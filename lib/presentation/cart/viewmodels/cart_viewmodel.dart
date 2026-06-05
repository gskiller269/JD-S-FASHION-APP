import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/repositories/auth_repository.dart';

class CartNotifier extends AsyncNotifier<List<CartItemWithProduct>> {
  late CartRepository _repository;

  @override
  FutureOr<List<CartItemWithProduct>> build() async {
    _repository = ref.watch(cartRepositoryProvider);
    final list = await _repository.getCart();

    // Auto-seed sample cart items if empty for demo purposes
    if (list.isEmpty) {
      try {
        final variantsResponse = await ref.read(supabaseProvider)
            .from('product_variants')
            .select('id')
            .limit(2);

        if (variantsResponse.isNotEmpty) {
          for (var item in variantsResponse) {
            final variantId = item['id'] as String;
            await _repository.addToCart(variantId, 1);
          }
          return await _repository.getCart();
        }
      } catch (e) {
        print('Cart auto-seed error: $e');
      }
    }
    return list;
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
