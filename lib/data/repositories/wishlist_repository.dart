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

  Future<List<ProductWithImage>> getWishlistPaginated({required int limit, required int offset}) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _supabase
        .from('wishlists')
        .select('*, products(*, product_images(image_url))')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

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

  Future<void> _ensureProfileExists(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        final email = _supabase.auth.currentUser?.email ?? 'user@example.com';
        final fullName = _supabase.auth.currentUser?.userMetadata?['full_name'] as String? ?? email.split('@').first;
        await _supabase.from('profiles').insert({
          'id': userId,
          'full_name': fullName,
          'avatar_url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
          'role': 'customer',
        });
        print('Created missing profile for user: $userId');
      }
    } catch (e) {
      print('Error in ensureProfileExists: $e');
    }
  }

  Future<void> addToWishlist(String productId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    await _ensureProfileExists(userId);

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
