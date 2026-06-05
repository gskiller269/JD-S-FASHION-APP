import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/wishlist_repository.dart';

class WishlistController extends GetxController {
  final WishlistRepository _wishlistRepository;
  final SupabaseClient _supabaseClient;
  final Function(String)? onRemoveCallback;

  WishlistController({
    required WishlistRepository wishlistRepository,
    required SupabaseClient supabaseClient,
    this.onRemoveCallback,
  })  : _wishlistRepository = wishlistRepository,
        _supabaseClient = supabaseClient;

  // Reactive variables
  var wishlistItems = <ProductWithImage>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;
  
  // Track which product ID is currently animating its heart icon
  var animatingHeartId = ''.obs;

  int _currentPage = 0;
  static const int _pageSize = 6;

  @override
  void onInit() {
    super.onInit();
    loadInitialWishlist();
  }

  // Load the first page of wishlist items
  Future<void> loadInitialWishlist() async {
    if (isLoading.value) return;

    isLoading.value = true;
    _currentPage = 0;
    hasMore.value = true;

    try {
      var items = await _wishlistRepository.getWishlistPaginated(
        limit: _pageSize,
        offset: 0,
      );
      
      // Auto-seed sample wishlist items if empty for demo purposes (matching Riverpod seeder)
      if (items.isEmpty && _supabaseClient.auth.currentUser != null) {
        try {
          final products = await _supabaseClient
              .from('products')
              .select('id')
              .eq('is_active', true)
              .limit(3);

          if (products.isNotEmpty) {
            for (var p in products) {
              final productId = p['id'] as String;
              try {
                await _wishlistRepository.addToWishlist(productId);
              } catch (_) {}
            }
            
            // Reload paginated list after seeding
            items = await _wishlistRepository.getWishlistPaginated(
              limit: _pageSize,
              offset: 0,
            );

            // Sync with Riverpod
            if (onRemoveCallback != null) {
              onRemoveCallback!('');
            }
          }
        } catch (e) {
          debugPrint('Wishlist auto-seed error: $e');
        }
      }
      
      wishlistItems.assignAll(items);
      
      if (items.length < _pageSize) {
        hasMore.value = false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load wishlist items',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load the next page of wishlist items (Infinite Scroll)
  Future<void> loadMoreWishlist() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    _currentPage++;

    try {
      final nextOffset = _currentPage * _pageSize;
      final newItems = await _wishlistRepository.getWishlistPaginated(
        limit: _pageSize,
        offset: nextOffset,
      );

      if (newItems.isEmpty) {
        hasMore.value = false;
      } else {
        wishlistItems.addAll(newItems);
        if (newItems.length < _pageSize) {
          hasMore.value = false;
        }
      }
    } catch (e) {
      _currentPage--; // Revert page count on failure
      Get.snackbar(
        'Error',
        'Failed to load more wishlist items',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  // Remove item from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    // Trigger heart animation
    animatingHeartId.value = productId;
    await Future.delayed(const Duration(milliseconds: 300));
    animatingHeartId.value = '';

    try {
      await _wishlistRepository.removeFromWishlist(productId);
      
      // Remove from local list
      wishlistItems.removeWhere((item) => item.product.id == productId);
      
      // Call external callback to keep Riverpod in sync
      if (onRemoveCallback != null) {
        onRemoveCallback!(productId);
      }
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not remove item from wishlist',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Move item to cart: Resolve variant, add to cart, and remove from wishlist
  Future<bool> moveToCart({
    required String productId,
    required Future<void> Function(String variantId) onAddToCart,
  }) async {
    try {
      // Find the first available variant ID for the product
      final response = await _supabaseClient
          .from('product_variants')
          .select('id')
          .eq('product_id', productId)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        Get.snackbar(
          'Error',
          'This product is currently out of stock or unavailable.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final variantId = response['id'] as String;

      // Add to cart via Riverpod's notifier (supplied via callback)
      await onAddToCart(variantId);

      // Remove from wishlist
      await _wishlistRepository.removeFromWishlist(productId);
      wishlistItems.removeWhere((item) => item.product.id == productId);

      // Call external callback to keep Riverpod in sync
      if (onRemoveCallback != null) {
        onRemoveCallback!(productId);
      }
      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not move item to cart',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  // Fetch product details dynamically (including variants) from Supabase
  Future<ProductWithDetails?> getProductDetails(String productId, String? imageUrl) async {
    try {
      final productResponse = await _supabaseClient
          .from('products')
          .select()
          .eq('id', productId)
          .maybeSingle();

      if (productResponse == null) return null;
      final product = ProductModel.fromJson(productResponse);

      final variantsResponse = await _supabaseClient
          .from('product_variants')
          .select('*, inventory(quantity)')
          .eq('product_id', productId);

      int totalInventory = 0;
      final List<Map<String, dynamic>> variants = [];

      for (var v in (variantsResponse as List)) {
        final inventoryList = v['inventory'] as List?;
        int qty = 0;
        if (inventoryList != null && inventoryList.isNotEmpty) {
          qty = (inventoryList.first['quantity'] as num?)?.toInt() ?? 0;
        }
        totalInventory += qty;
        variants.add({
          'id': v['id'],
          'color': v['color'],
          'size': v['size'],
          'sku': v['sku'],
          'price_adjustment': (v['price_adjustment'] as num?)?.toDouble() ?? 0.0,
          'quantity': qty,
        });
      }

      return ProductWithDetails(
        product: product,
        imageUrl: imageUrl,
        totalInventory: totalInventory,
        variants: variants,
      );
    } catch (e) {
      debugPrint('Error loading product details: $e');
      return null;
    }
  }
}
