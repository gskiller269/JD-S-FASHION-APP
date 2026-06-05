import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'auth_repository.dart';

class ProductWithImage {
  final ProductModel product;
  final String? imageUrl;

  ProductWithImage({required this.product, this.imageUrl});
}

class ProductWithDetails {
  final ProductModel product;
  final String? imageUrl;
  final int totalInventory;
  final List<Map<String, dynamic>> variants;

  ProductWithDetails({
    required this.product,
    this.imageUrl,
    this.totalInventory = 0,
    this.variants = const [],
  });

  ProductWithDetails copyWith({
    ProductModel? product,
    String? imageUrl,
    int? totalInventory,
    List<Map<String, dynamic>>? variants,
  }) {
    return ProductWithDetails(
      product: product ?? this.product,
      imageUrl: imageUrl ?? this.imageUrl,
      totalInventory: totalInventory ?? this.totalInventory,
      variants: variants ?? this.variants,
    );
  }
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

  Future<List<ProductWithImage>> getProductsWithImages({int limit = 20, int offset = 0}) async {
    final response = await _supabase
        .from('products')
        .select('*, product_images(image_url)')
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((json) {
      final product = ProductModel.fromJson(json);
      final images = json['product_images'] as List?;
      final imageUrl = (images != null && images.isNotEmpty)
          ? images.first['image_url'] as String?
          : null;
      return ProductWithImage(product: product, imageUrl: imageUrl);
    }).toList();
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

  Future<List<ProductWithDetails>> getProductsByCategoryPaginated(
    String categoryId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('products')
        .select('*, product_images(image_url), product_variants(id, color, size, sku, price_adjustment, inventory(quantity))')
        .eq('category_id', categoryId)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) {
      final product = ProductModel.fromJson(json);
      final images = json['product_images'] as List?;
      final imageUrl = (images != null && images.isNotEmpty)
          ? images.first['image_url'] as String?
          : null;

      final variantsJson = json['product_variants'] as List? ?? [];
      int totalInventory = 0;
      final List<Map<String, dynamic>> variants = [];

      for (var v in variantsJson) {
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
    }).toList();
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
