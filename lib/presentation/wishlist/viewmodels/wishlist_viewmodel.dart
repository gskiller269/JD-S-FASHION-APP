import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/wishlist_repository.dart';
import '../../../data/repositories/product_repository.dart';

class WishlistNotifier extends AsyncNotifier<List<ProductWithImage>> {
  late WishlistRepository _repository;

  @override
  FutureOr<List<ProductWithImage>> build() async {
    _repository = ref.watch(wishlistRepositoryProvider);
    final list = await _repository.getWishlist();

    // Auto-seed sample wishlist items if empty for demo purposes
    if (list.isEmpty) {
      try {
        final products = await ref.read(productRepositoryProvider).getProductsWithImages(limit: 3);
        if (products.isNotEmpty) {
          for (var p in products) {
            await _repository.addToWishlist(p.product.id);
          }
          return await _repository.getWishlist();
        }
      } catch (e) {
        print('Wishlist auto-seed error: $e');
      }
    }
    return list;
  }

  Future<void> toggleWishlist(String productId) async {
    final list = state.value ?? [];
    final alreadyWishlisted = list.any((item) => item.product.id == productId);

    state = const AsyncValue.loading();
    try {
      if (alreadyWishlisted) {
        await _repository.removeFromWishlist(productId);
      } else {
        await _repository.addToWishlist(productId);
      }
      // Reload wishlist data
      final newList = await _repository.getWishlist();
      state = AsyncValue.data(newList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool isProductWishlisted(String productId) {
    final list = state.value ?? [];
    return list.any((item) => item.product.id == productId);
  }
}

final wishlistProvider = AsyncNotifierProvider<WishlistNotifier, List<ProductWithImage>>(() {
  return WishlistNotifier();
});
