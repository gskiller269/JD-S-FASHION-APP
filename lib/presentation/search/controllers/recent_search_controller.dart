import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';

class RecentSearchState {
  final List<String> recentQueries;
  final List<ProductWithImage> recentProducts;

  RecentSearchState({
    this.recentQueries = const [],
    this.recentProducts = const [],
  });
}

class RecentSearchNotifier extends AsyncNotifier<RecentSearchState> {
  static const _queriesKey = 'recent_queries';
  static const _productsKey = 'recent_products';

  @override
  Future<RecentSearchState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final queries = prefs.getStringList(_queriesKey) ?? [];
    final productsEncoded = prefs.getStringList(_productsKey) ?? [];
    
    final List<ProductWithImage> products = [];
    for (var encoded in productsEncoded) {
      try {
        final decoded = json.decode(encoded) as Map<String, dynamic>;
        final productJson = decoded['product'] as Map<String, dynamic>;
        final imageUrl = decoded['imageUrl'] as String?;
        final product = ProductModel.fromJson(productJson);
        products.add(ProductWithImage(product: product, imageUrl: imageUrl));
      } catch (e) {
        // Ignore parsing errors for individual corrupt entries
      }
    }
    
    return RecentSearchState(
      recentQueries: queries,
      recentProducts: products,
    );
  }

  Future<void> addQuery(String query) async {
    if (query.trim().isEmpty) return;
    
    final currentState = state.value ?? RecentSearchState();
    final cleanQuery = query.trim();
    
    // Remove query if it already exists to move it to the top/front
    final updatedQueries = List<String>.from(currentState.recentQueries)
      ..remove(cleanQuery)
      ..insert(0, cleanQuery);
      
    // Limit to 10 queries
    if (updatedQueries.length > 10) {
      updatedQueries.removeLast();
    }
    
    state = AsyncValue.data(RecentSearchState(
      recentQueries: updatedQueries,
      recentProducts: currentState.recentProducts,
    ));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_queriesKey, updatedQueries);
  }

  Future<void> removeQuery(String query) async {
    final currentState = state.value ?? RecentSearchState();
    final updatedQueries = List<String>.from(currentState.recentQueries)
      ..remove(query);
      
    state = AsyncValue.data(RecentSearchState(
      recentQueries: updatedQueries,
      recentProducts: currentState.recentProducts,
    ));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_queriesKey, updatedQueries);
  }

  Future<void> clearQueries() async {
    final currentState = state.value ?? RecentSearchState();
    
    state = AsyncValue.data(RecentSearchState(
      recentQueries: [],
      recentProducts: currentState.recentProducts,
    ));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queriesKey);
  }

  Future<void> addProduct(ProductWithImage productWithImage) async {
    final currentState = state.value ?? RecentSearchState();
    
    // Remove product if it already exists in the list to move it to the front
    final updatedProducts = List<ProductWithImage>.from(currentState.recentProducts)
      ..removeWhere((p) => p.product.id == productWithImage.product.id)
      ..insert(0, productWithImage);
      
    // Limit to 10 products
    if (updatedProducts.length > 10) {
      updatedProducts.removeLast();
    }
    
    state = AsyncValue.data(RecentSearchState(
      recentQueries: currentState.recentQueries,
      recentProducts: updatedProducts,
    ));
    
    final prefs = await SharedPreferences.getInstance();
    final productsEncoded = updatedProducts.map((p) {
      return json.encode({
        'product': p.product.toJson(),
        'imageUrl': p.imageUrl,
      });
    }).toList();
    await prefs.setStringList(_productsKey, productsEncoded);
  }

  Future<void> removeProduct(String productId) async {
    final currentState = state.value ?? RecentSearchState();
    final updatedProducts = List<ProductWithImage>.from(currentState.recentProducts)
      ..removeWhere((p) => p.product.id == productId);
      
    state = AsyncValue.data(RecentSearchState(
      recentQueries: currentState.recentQueries,
      recentProducts: updatedProducts,
    ));
    
    final prefs = await SharedPreferences.getInstance();
    final productsEncoded = updatedProducts.map((p) {
      return json.encode({
        'product': p.product.toJson(),
        'imageUrl': p.imageUrl,
      });
    }).toList();
    await prefs.setStringList(_productsKey, productsEncoded);
  }

  Future<void> clearProducts() async {
    final currentState = state.value ?? RecentSearchState();
    
    state = AsyncValue.data(RecentSearchState(
      recentQueries: currentState.recentQueries,
      recentProducts: [],
    ));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_productsKey);
  }
}

final recentSearchProvider = AsyncNotifierProvider<RecentSearchNotifier, RecentSearchState>(() {
  return RecentSearchNotifier();
});
