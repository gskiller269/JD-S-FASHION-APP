import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';

// ── Categories ──────────────────────────────────────────────────────────────

final categoriesProvider = AsyncNotifierProvider<CategoriesNotifier, List<CategoryModel>>(() {
  return CategoriesNotifier();
});

class CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  FutureOr<List<CategoryModel>> build() {
    return ref.watch(categoryRepositoryProvider).getCategories();
  }
}

// ── Featured / New Arrival Products ─────────────────────────────────────────

final featuredProductsProvider = AsyncNotifierProvider<FeaturedProductsNotifier, List<ProductWithImage>>(() {
  return FeaturedProductsNotifier();
});

class FeaturedProductsNotifier extends AsyncNotifier<List<ProductWithImage>> {
  @override
  FutureOr<List<ProductWithImage>> build() {
    return ref.watch(productRepositoryProvider).getProductsWithImages(limit: 10);
  }
}

// ── Products by Category ────────────────────────────────────────────────────

final productsByCategoryProvider = FutureProvider.family<List<ProductModel>, String>((ref, categoryId) {
  return ref.watch(productRepositoryProvider).getProductsByCategory(categoryId);
});

// ── Search ──────────────────────────────────────────────────────────────────

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String query) => state = query;
}

final searchResultsProvider = FutureProvider<List<ProductWithImage>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return ref.watch(productRepositoryProvider).searchProducts(query);
});
