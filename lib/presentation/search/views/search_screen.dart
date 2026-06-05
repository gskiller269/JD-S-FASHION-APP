import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/viewmodels/home_viewmodel.dart';
import '../../../data/repositories/product_repository.dart';
import '../controllers/recent_search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsState = ref.watch(searchResultsProvider);

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.darkAccent,
              size: 18,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed('home');
              }
            },
          ),
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search premium fashion...',
                  hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.burgundy, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                            ref.read(searchQueryProvider.notifier).update('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.darkAccent),
                onChanged: (query) {
                  setState(() {}); // Redraw suffix icon
                  ref.read(searchQueryProvider.notifier).update(query.trim());
                },
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    ref.read(recentSearchProvider.notifier).addQuery(query.trim());
                  }
                },
              ),
            ),
          ),
        ),
        body: resultsState.when(
          data: (products) {
            if (products.isEmpty) {
              if (_searchController.text.trim().isEmpty) {
                return _buildEmptyPlaceholder(context);
              }
              return _buildNoResultsPlaceholder(context);
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];
                return _SearchProductCard(
                  item: item,
                  onTap: () {
                    // Save query if present
                    final query = _searchController.text.trim();
                    if (query.isNotEmpty) {
                      ref.read(recentSearchProvider.notifier).addQuery(query);
                    }
                    
                    // Save product to recent products
                    ref.read(recentSearchProvider.notifier).addProduct(item);

                    // Navigate to product details
                    final product = item.product;
                    final productDetails = ProductWithDetails(
                      product: product,
                      imageUrl: item.imageUrl ?? 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=400&q=80',
                      totalInventory: 20,
                      variants: [
                        {'id': 'var-m-${product.id}', 'color': 'Midnight Black', 'size': 'M', 'quantity': 10, 'price_adjustment': 0.0},
                        {'id': 'var-l-${product.id}', 'color': 'Classic Navy', 'size': 'L', 'quantity': 10, 'price_adjustment': 100.0},
                      ],
                    );
                    context.push('/product-details', extra: productDetails);
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.burgundy),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 60, color: AppTheme.burgundy),
                const SizedBox(height: 16),
                Text(
                  'Search encountered an error',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final recentState = ref.watch(recentSearchProvider);

    return recentState.when(
      data: (data) {
        final hasQueries = data.recentQueries.isNotEmpty;
        final hasProducts = data.recentProducts.isNotEmpty;

        if (!hasQueries && !hasProducts) {
          return _buildDefaultPlaceholder(context);
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            if (hasQueries) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkAccent,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(recentSearchProvider.notifier).clearQueries();
                    },
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.recentQueries.map((query) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _searchController.text = query;
                        });
                        ref.read(searchQueryProvider.notifier).update(query);
                        ref.read(recentSearchProvider.notifier).addQuery(query);
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              query,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: AppTheme.darkAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                ref.read(recentSearchProvider.notifier).removeQuery(query);
                              },
                              child: const Icon(Icons.close, size: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (hasProducts) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Viewed Products',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkAccent,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(recentSearchProvider.notifier).clearProducts();
                    },
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.recentProducts.length,
                  itemBuilder: (context, index) {
                    final item = data.recentProducts[index];
                    final product = item.product;
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final productDetails = ProductWithDetails(
                                product: product,
                                imageUrl: item.imageUrl ?? 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=400&q=80',
                                totalInventory: 20,
                                variants: [
                                  {'id': 'var-m-${product.id}', 'color': 'Midnight Black', 'size': 'M', 'quantity': 10, 'price_adjustment': 0.0},
                                  {'id': 'var-l-${product.id}', 'color': 'Classic Navy', 'size': 'L', 'quantity': 10, 'price_adjustment': 100.0},
                                ],
                              );
                              // Refresh position in history list
                              ref.read(recentSearchProvider.notifier).addProduct(item);
                              context.push('/product-details', extra: productDetails);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            item.imageUrl!,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                                          )
                                        : _buildFallbackImage(),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.darkAccent,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${(product.discountPrice ?? product.basePrice).toInt()}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.burgundy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                ref.read(recentSearchProvider.notifier).removeProduct(product.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.burgundy),
        ),
      ),
      error: (e, s) => _buildDefaultPlaceholder(context),
    );
  }

  Widget _buildDefaultPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Search for your style',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find shirts, shoes, watches & more',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sentiment_dissatisfied_rounded, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else like "shirt" or "watch"',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: AppTheme.burgundy.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.checkroom,
          size: 30,
          color: AppTheme.burgundy.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _SearchProductCard extends StatelessWidget {
  final ProductWithImage item;
  final VoidCallback onTap;
  const _SearchProductCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: hasImage
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                            )
                          : _buildFallbackImage(),
                    ),
                  ],
                ),
              ),
            ),
            // Product Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkAccent,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${(product.discountPrice ?? product.basePrice).toInt()}',
                              style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.burgundy),
                            ),
                            if (product.discountPrice != null)
                              Text(
                                '₹${product.basePrice.toInt()}',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.gold, size: 20),
                          onPressed: onTap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: AppTheme.burgundy.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.checkroom,
          size: 40,
          color: AppTheme.burgundy.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
