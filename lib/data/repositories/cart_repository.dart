import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class CartItemWithProduct {
  final String id;
  final String variantId;
  final String productId;
  final int quantity;
  final String productName;
  final double price; // Discount price or base price + price adjustment
  final String? color;
  final String? size;
  final String? imageUrl;

  CartItemWithProduct({
    required this.id,
    required this.variantId,
    required this.productId,
    required this.quantity,
    required this.productName,
    required this.price,
    this.color,
    this.size,
    this.imageUrl,
  });
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(supabaseProvider));
});

class CartRepository {
  final SupabaseClient _supabase;

  CartRepository(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  Future<List<CartItemWithProduct>> getCart() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _supabase
        .from('cart_items')
        .select('*, product_variants(*, products(*, product_images(image_url)))')
        .eq('user_id', userId);

    return (response as List).map((json) {
      final id = json['id'] as String;
      final quantity = json['quantity'] as int;
      final variantJson = json['product_variants'] as Map<String, dynamic>;
      final variantId = variantJson['id'] as String;
      final color = variantJson['color'] as String?;
      final size = variantJson['size'] as String?;
      final priceAdjustment = (variantJson['price_adjustment'] as num?)?.toDouble() ?? 0.0;

      final productJson = variantJson['products'] as Map<String, dynamic>;
      final productId = productJson['id'] as String;
      final productName = productJson['name'] as String;
      
      final basePrice = (productJson['base_price'] as num).toDouble();
      final discountPrice = (productJson['discount_price'] as num?)?.toDouble();
      final activePrice = (discountPrice ?? basePrice) + priceAdjustment;

      final images = productJson['product_images'] as List?;
      final imageUrl = (images != null && images.isNotEmpty)
          ? images.first['image_url'] as String?
          : null;

      return CartItemWithProduct(
        id: id,
        variantId: variantId,
        productId: productId,
        quantity: quantity,
        productName: productName,
        price: activePrice,
        color: color,
        size: size,
        imageUrl: imageUrl,
      );
    }).toList();
  }

  Future<void> addToCart(String variantId, int quantity) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('cart_items').upsert({
      'user_id': userId,
      'variant_id': variantId,
      'quantity': quantity,
    }, onConflict: 'user_id, variant_id');
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _supabase
        .from('cart_items')
        .delete()
        .eq('id', cartItemId);
  }

  Future<void> clearCart() async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _supabase
        .from('cart_items')
        .delete()
        .eq('user_id', userId);
  }
}
