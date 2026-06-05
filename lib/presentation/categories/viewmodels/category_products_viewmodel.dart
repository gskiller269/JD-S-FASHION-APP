import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/product_model.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/auth_repository.dart';
import 'dart:math';

class CategoryProductsState {
  final List<ProductWithDetails> products;
  final bool isLoading;
  final bool isLoadMoreRunning;
  final bool hasMore;
  final String? error;
  final CategoryModel? category;

  CategoryProductsState({
    this.products = const [],
    this.isLoading = true,
    this.isLoadMoreRunning = false,
    this.hasMore = true,
    this.error,
    this.category,
  });

  CategoryProductsState copyWith({
    List<ProductWithDetails>? products,
    bool? isLoading,
    bool? isLoadMoreRunning,
    bool? hasMore,
    String? error,
    CategoryModel? category,
  }) {
    return CategoryProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadMoreRunning: isLoadMoreRunning ?? this.isLoadMoreRunning,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      category: category ?? this.category,
    );
  }
}

class CategoryProductsNotifier extends Notifier<CategoryProductsState> {
  late ProductRepository _productRepository;
  late CategoryRepository _categoryRepository;
  late SupabaseClient _supabase;
  RealtimeChannel? _realtimeChannel;

  int _offset = 0;
  static const int _limit = 20;
  Timer? _mockSimulationTimer;
  String? _categorySlug;

  @override
  CategoryProductsState build() {
    _productRepository = ref.watch(productRepositoryProvider);
    _categoryRepository = ref.watch(categoryRepositoryProvider);
    _supabase = ref.watch(supabaseProvider);

    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _mockSimulationTimer?.cancel();
    });

    return CategoryProductsState(isLoading: false, products: []);
  }

  Future<void> setSlug(String slug) async {
    if (_categorySlug == slug && state.products.isNotEmpty) return;
    _categorySlug = slug;

    // Reset state and cancel old listeners
    _realtimeChannel?.unsubscribe();
    _mockSimulationTimer?.cancel();

    state = CategoryProductsState(isLoading: true);
    try {
      // 1. Fetch category by slug
      final category = await _categoryRepository.getCategoryBySlug(slug);
      if (category == null) {
        state = state.copyWith(isLoading: false, error: 'Category not found');
        return;
      }
      state = state.copyWith(category: category);

      // 2. Load first page of products
      _offset = 0;
      final dbProducts = await _productRepository.getProductsByCategoryPaginated(
        category.id,
        limit: _limit,
        offset: _offset,
      );

      List<ProductWithDetails> allProducts = [...dbProducts];

      // 3. For the "shirts" category, if we don't have enough shirts (to show off the premium infinite scroll),
      // we generate realistic shirts in memory up to page size.
      if (slug == 'shirts') {
        final mockShirts = _generateMockShirts(category.id, startOffset: allProducts.length);
        allProducts.addAll(mockShirts.take(_limit - allProducts.length));
      }

      state = state.copyWith(
        products: allProducts,
        isLoading: false,
        hasMore: allProducts.isNotEmpty,
      );

      _offset = allProducts.length;

      // 4. Setup Real-time listener for inventory
      _setupRealtimeInventory();

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadMoreRunning || !state.hasMore || _categorySlug == null) return;

    state = state.copyWith(isLoadMoreRunning: true);
    try {
      final category = state.category;
      if (category == null) return;

      final dbProducts = await _productRepository.getProductsByCategoryPaginated(
        category.id,
        limit: _limit,
        offset: _offset,
      );

      List<ProductWithDetails> newProducts = [...dbProducts];

      // If category is shirts, continue generating mock shirts to demo infinite scroll
      if (_categorySlug == 'shirts' && _offset < 60) {
        final mockShirts = _generateMockShirts(category.id, startOffset: _offset);
        final neededMockCount = _limit - newProducts.length;
        if (neededMockCount > 0) {
          newProducts.addAll(mockShirts.take(neededMockCount));
        }
      }

      if (newProducts.isEmpty) {
        state = state.copyWith(
          isLoadMoreRunning: false,
          hasMore: false,
        );
      } else {
        state = state.copyWith(
          products: [...state.products, ...newProducts],
          isLoadMoreRunning: false,
          hasMore: newProducts.length >= _limit,
        );
        _offset += newProducts.length;
      }
    } catch (e) {
      state = state.copyWith(isLoadMoreRunning: false, error: e.toString());
    }
  }

  void _setupRealtimeInventory() {
    if (_categorySlug == null) return;

    // Listen to real-time updates for the inventory table in Supabase
    _realtimeChannel = _supabase
        .channel('public:inventory')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'inventory',
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord == null) return;

            final variantId = newRecord['variant_id'] as String?;
            final quantity = (newRecord['quantity'] as num?)?.toInt() ?? 0;

            if (variantId != null) {
              _updateProductStock(variantId, quantity);
            }
          },
        );
    
    _realtimeChannel?.subscribe();

    // To simulate "real-time inventory updates" for the mock products (since they aren't in Supabase),
    // we trigger a periodic timer that slightly fluctuates mock products' stock level.
    if (_categorySlug == 'shirts') {
      _startMockInventorySimulation();
    }
  }

  void _startMockInventorySimulation() {
    _mockSimulationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final random = Random();
      // Select a random mock product
      final mockProducts = state.products.where((p) => p.product.id.startsWith('mock-')).toList();
      if (mockProducts.isEmpty) return;

      final randomProduct = mockProducts[random.nextInt(mockProducts.length)];
      if (randomProduct.variants.isEmpty) return;

      final variantIndex = random.nextInt(randomProduct.variants.length);
      final variant = randomProduct.variants[variantIndex];
      final currentQty = variant['quantity'] as int;
      
      // Decrease or increase stock slightly
      int change = random.nextBool() ? -1 : 1;
      int newQty = max(0, currentQty + change);

      final updatedVariants = List<Map<String, dynamic>>.from(randomProduct.variants);
      updatedVariants[variantIndex] = {
        ...variant,
        'quantity': newQty,
      };

      int newTotalInventory = updatedVariants.fold(0, (sum, v) => sum + (v['quantity'] as int));

      final updatedProduct = randomProduct.copyWith(
        variants: updatedVariants,
        totalInventory: newTotalInventory,
      );

      final newProducts = state.products.map((p) {
        return p.product.id == randomProduct.product.id ? updatedProduct : p;
      }).toList();

      state = state.copyWith(products: newProducts);
    });
  }

  void _updateProductStock(String variantId, int newQuantity) {
    bool updated = false;
    final updatedProducts = state.products.map((p) {
      final variantIdx = p.variants.indexWhere((v) => v['id'] == variantId);
      if (variantIdx != -1) {
        final newVariants = List<Map<String, dynamic>>.from(p.variants);
        newVariants[variantIdx] = {
          ...newVariants[variantIdx],
          'quantity': newQuantity,
        };
        int newTotal = newVariants.fold(0, (sum, v) => sum + (v['quantity'] as int));
        updated = true;
        return p.copyWith(variants: newVariants, totalInventory: newTotal);
      }
      return p;
    }).toList();

    if (updated) {
      state = state.copyWith(products: updatedProducts);
    }
  }

  List<ProductWithDetails> _generateMockShirts(String categoryId, {int startOffset = 0}) {
    final List<Map<String, dynamic>> shirtTemplates = [
      {'name': 'Black Shirt', 'price': 899.00, 'rating': 4.5, 'reviews': 120, 'discount': 0.15, 'img': 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=600&q=80'},
      {'name': 'White Shirt', 'price': 949.00, 'rating': 4.7, 'reviews': 95, 'discount': 0.10, 'img': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=600&q=80'},
      {'name': 'Denim Shirt', 'price': 999.00, 'rating': 4.4, 'reviews': 82, 'discount': 0.05, 'img': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=600&q=80'},
      {'name': 'Checked Shirt', 'price': 899.00, 'rating': 4.2, 'reviews': 110, 'discount': null, 'img': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80'},
      {'name': 'Striped Shirt', 'price': 899.00, 'rating': 4.6, 'reviews': 64, 'discount': 0.20, 'img': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80'},
      {'name': 'Olive Shirt', 'price': 799.00, 'rating': 4.3, 'reviews': 54, 'discount': 0.08, 'img': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80'},
      {'name': 'Formal Shirt', 'price': 1199.00, 'rating': 4.8, 'reviews': 150, 'discount': 0.12, 'img': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80'},
      {'name': 'Casual Shirt', 'price': 999.00, 'rating': 4.1, 'reviews': 77, 'discount': null, 'img': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80'},
      {'name': 'Linen Shirt', 'price': 1299.00, 'rating': 4.9, 'reviews': 188, 'discount': 0.25, 'img': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80'},
      {'name': 'Slim Fit Shirt', 'price': 1099.00, 'rating': 4.6, 'reviews': 102, 'discount': null, 'img': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&q=80'},
    ];

    final List<ProductWithDetails> generated = [];
    final int countToGenerate = 60;

    for (int i = 0; i < countToGenerate; i++) {
      final index = (startOffset + i) % shirtTemplates.length;
      final template = shirtTemplates[index];
      final templateName = template['name'] as String;
      final shirtNum = (startOffset + i) ~/ shirtTemplates.length + 1;
      final name = shirtNum > 1 ? '$templateName v$shirtNum' : templateName;

      final double basePrice = template['price'] as double;
      final double? discountPct = template['discount'] as double?;
      final double? discountPrice = discountPct != null ? basePrice * (1.0 - discountPct) : null;

      final String id = 'mock-shirt-${startOffset + i}';
      final String slug = 'mock-shirt-${startOffset + i}';

      final product = ProductModel(
        id: id,
        vendorId: 'e0000000-0000-0000-0000-000000000001',
        categoryId: categoryId,
        name: name,
        slug: slug,
        description: 'A stylish and premium $name perfect for daily luxury wear. Breathable high-quality fabric offering absolute comfort.',
        basePrice: basePrice,
        discountPrice: discountPrice,
        isActive: true,
      );

      final List<Map<String, dynamic>> variants = [
        {
          'id': 'mock-variant-$id-M',
          'color': 'Default Color',
          'size': 'M',
          'sku': 'SKU-$id-M',
          'price_adjustment': 0.00,
          'quantity': 5 + Random().nextInt(15),
        },
        {
          'id': 'mock-variant-$id-L',
          'color': 'Default Color',
          'size': 'L',
          'sku': 'SKU-$id-L',
          'price_adjustment': 0.00,
          'quantity': 2 + Random().nextInt(10),
        }
      ];

      final totalQty = variants.fold<int>(0, (sum, v) => sum + (v['quantity'] as int));

      generated.add(ProductWithDetails(
        product: product,
        imageUrl: template['img'] as String,
        totalInventory: totalQty,
        variants: variants,
      ));
    }

    return generated;
  }
}

final categoryProductsProvider = NotifierProvider<CategoryProductsNotifier, CategoryProductsState>(
  CategoryProductsNotifier.new,
);
