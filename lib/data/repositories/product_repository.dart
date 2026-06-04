import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'auth_repository.dart';

class ProductWithImage {
  final ProductModel product;
  final String? imageUrl;

  ProductWithImage({required this.product, this.imageUrl});
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(supabaseProvider));
});

class ProductRepository {
  final SupabaseClient _supabase;

  ProductRepository(this._supabase);

  Future<List<ProductModel>> getProducts({int limit = 20, int offset = 0}) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<List<ProductModel>> getProductsByCategory(String categoryId, {int limit = 20}) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('category_id', categoryId)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  Future<ProductModel?> getProductBySlug(String slug) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('slug', slug)
        .maybeSingle();
    if (response == null) return null;
    return ProductModel.fromJson(response);
  }

  Future<ProductModel?> getProductById(String id) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return ProductModel.fromJson(response);
  }

  Future<List<ProductWithImage>> searchProducts(String query) async {
    final response = await _supabase
        .from('products')
        .select('*, product_images(image_url)')
        .eq('is_active', true)
        .ilike('name', '%$query%')
        .limit(30);
    return (response as List).map((json) {
      final product = ProductModel.fromJson(json);
      final images = json['product_images'] as List?;
      final imageUrl = (images != null && images.isNotEmpty)
          ? images.first['image_url'] as String?
          : null;
      return ProductWithImage(product: product, imageUrl: imageUrl);
    }).toList();
  }
}
