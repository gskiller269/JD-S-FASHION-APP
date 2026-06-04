import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'auth_repository.dart';
import 'product_repository.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(supabaseProvider));
});

class WishlistRepository {
  final SupabaseClient _supabase;

  WishlistRepository(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  Future<List<ProductWithImage>> getWishlist() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _supabase
        .from('wishlists')
        .select('*, products(*, product_images(image_url))')
        .eq('user_id', userId);

    return (response as List).map((json) {
      final productJson = json['products'] as Map<String, dynamic>;
      final product = ProductModel.fromJson(productJson);
      final images = productJson['product_images'] as List?;
      final imageUrl = (images != null && images.isNotEmpty)
          ? images.first['image_url'] as String?
          : null;
      return ProductWithImage(product: product, imageUrl: imageUrl);
    }).toList();
  }

  Future<bool> isWishlisted(String productId) async {
    final userId = _currentUserId;
    if (userId == null) return false;

    final response = await _supabase
        .from('wishlists')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    return response != null;
  }

  Future<void> addToWishlist(String productId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('wishlists').insert({
      'user_id': userId,
      'product_id': productId,
    });
  }

  Future<void> removeFromWishlist(String productId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('wishlists')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);
  }
}
