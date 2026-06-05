import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../wishlist/viewmodels/wishlist_viewmodel.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/models/product_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  // Premium category data with Unsplash fashion product thumbnails
  final List<Map<String, String>> _categories = [
    {
      'name': 'Shirts',
      'slug': 'shirts',
      'image': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=250&q=80',
    },
    {
      'name': 'T-Shirts',
      'slug': 't-shirts',
      'image': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=250&q=80',
    },
    {
      'name': 'Jeans',
      'slug': 'jeans',
      'image': 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=250&q=80',
    },
    {
      'name': 'Jackets',
      'slug': 'jackets',
      'image': 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=250&q=80',
    },
    {
      'name': 'Shoes',
      'slug': 'shoes',
      'image': 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=250&q=80',
    },
  ];

  // Best seller demo products
  final List<Map<String, dynamic>> _bestSellers = [
    {
      'id': '1',
      'name': 'Casual Linen Shirt',
      'price': 1499.0,
      'discountPrice': 899.0,
      'image': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&q=80',
      'rating': 4.7,
      'reviews': 240,
    },
    {
      'id': '2',
      'name': 'Printed Resort Shirt',
      'price': 1799.0,
      'discountPrice': 999.0,
      'image': 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=400&q=80',
      'rating': 4.5,
      'reviews': 185,
    },
    {
      'id': '3',
      'name': 'Distressed Denim Jacket',
      'price': 2999.0,
      'discountPrice': 1499.0,
      'image': 'https://images.unsplash.com/photo-1576871337622-98d48d4aa53e?w=400&q=80',
      'rating': 4.8,
      'reviews': 312,
    },
    {
      'id': '4',
      'name': 'Classic White T-Shirt',
      'price': 999.0,
      'discountPrice': 599.0,
      'image': 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=400&q=80',
      'rating': 4.6,
      'reviews': 148,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Restrict viewport width on wide screens/desktops to maintain pixel-perfect mobile-first layout
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      backgroundColor: isLargeScreen ? const Color(0xFFF5F5F5) : Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Top Header Section
                _buildHeader(context),
                
                // Main Content
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // Search Bar
                      SliverToBoxAdapter(child: _buildSearchBar(context)),
                      
                      // Hero Promo Banner
                      SliverToBoxAdapter(child: _buildHeroBanner(context)),
                      
                      // Service Feature Highlights Row
                      SliverToBoxAdapter(child: _buildFeatureHighlightsRow()),
                      
                      // Top Categories Section
                      SliverToBoxAdapter(child: _buildCategoriesSection(context)),
                      
                      // Best Sellers Section
                      SliverToBoxAdapter(child: _buildBestSellersSection(context)),
                      
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
                
                // Bottom Navigation Bar
                _buildBottomNavigationBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final wishlistCount = ref.watch(wishlistProvider).value?.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Hamburger menu
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF222222), size: 26),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            
            // Centered Brand Title Logo
            Text(
              "JD'S FASHION",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                color: const Color(0xFF222222),
              ),
            ),
            
            // Wishlist Icon with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () => context.pushNamed('wishlist'),
                  icon: const Icon(Icons.favorite_border_rounded, color: Color(0xFF222222), size: 26),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (wishlistCount > 0)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF800020), // Primary Burgundy
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$wishlistCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: GestureDetector(
        onTap: () => context.pushNamed('search'),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5), // Soft Gray
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Search for shirts, jeans, watches...",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: const Color(0xFF222222).withOpacity(0.4),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF222222),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 220, // Increased height to prevent overflow
        decoration: BoxDecoration(
          color: const Color(0xFFF3E8DD), // Soft Beige Accent
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image: Fashion model wearing stylish jacket
            Align(
              alignment: Alignment.centerRight,
              child: FractionalTranslation(
                translation: const Offset(0.05, 0),
                child: Image.asset(
                  'assets/images/home_hero.png',
                  fit: BoxFit.cover,
                  width: 250,
                  alignment: const Alignment(0, -0.3),
                ),
              ),
            ),
            
            // Warm overlay gradient for text contrast
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFFF3E8DD).withOpacity(0.95),
                    const Color(0xFFF3E8DD).withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),
            
            // Text and CTA
            Padding(
              padding: const EdgeInsets.all(20.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "NEW ARRIVALS",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: const Color(0xFF800020), // Primary Burgundy
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Summer\nCollection '24",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF222222),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF800020),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF800020).withOpacity(0.3),
                    ),
                    child: Text(
                      "Explore Now",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlightsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHighlightItem(Icons.verified_outlined, "100% Original"),
          _buildHighlightItem(Icons.swap_horiz_outlined, "15 Days Return"),
          _buildHighlightItem(Icons.security_outlined, "Secure Pay"),
          _buildHighlightItem(Icons.local_shipping_outlined, "Fast Delivery"),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF222222), // Minimal monochrome
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF222222),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return categoriesState.maybeWhen(
      data: (dbCategories) {
        final list = dbCategories.isEmpty 
            ? _categories 
            : dbCategories.map((c) => {
                'name': c.name,
                'slug': c.slug,
                'image': c.imageUrl ?? 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=250&q=80',
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Top Categories",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF222222),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed('categories'),
                    child: Text(
                      "View All",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF800020),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Category Horizontal List
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final cat = list[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => context.pushNamed('category', pathParameters: {'slug': cat['slug']!}),
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF3E8DD), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: cat['image']!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFFF5F5F5),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF800020),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name']!,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF222222),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      orElse: () => _buildCategoriesFallbackSection(context),
    );
  }

  Widget _buildCategoriesFallbackSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Categories",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF222222),
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('categories'),
                child: Text(
                  "View All",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF800020),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => context.pushNamed('category', pathParameters: {'slug': cat['slug']!}),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF3E8DD), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: cat['image']!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF800020),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name']!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBestSellersSection(BuildContext context) {
    final featuredProductsState = ref.watch(featuredProductsProvider);
    final wishlist = ref.watch(wishlistProvider).value ?? [];

    return featuredProductsState.maybeWhen(
      data: (dbProducts) {
        if (dbProducts.isEmpty) {
          return _buildBestSellersFallbackSection(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Best Sellers",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF222222),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      "View All",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF800020),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: dbProducts.length,
                itemBuilder: (context, index) {
                  final item = dbProducts[index];
                  final product = item.product;
                  final imageUrl = item.imageUrl ?? 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=400&q=80';
                  
                  final isWishlisted = wishlist.any((w) => w.product.id == product.id);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () {
                        final productDetails = ProductWithDetails(
                          product: product,
                          imageUrl: imageUrl,
                          totalInventory: 20,
                          variants: [
                            {'id': 'var-m-${product.id}', 'color': 'Midnight Black', 'size': 'M', 'quantity': 10, 'price_adjustment': 0.0},
                            {'id': 'var-l-${product.id}', 'color': 'Classic Navy', 'size': 'L', 'quantity': 10, 'price_adjustment': 100.0},
                          ],
                        );
                        context.push('/product-details', extra: productDetails);
                      },
                      child: Container(
                        width: 155,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: const Color(0xFFF5F5F5),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF800020),
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () async {
                                      try {
                                        await ref.read(wishlistProvider.notifier).toggleWishlist(product.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(isWishlisted 
                                                ? '${product.name} removed from wishlist' 
                                                : '${product.name} added to wishlist'),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: const Color(0xFF800020),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to update wishlist: $e'),
                                              behavior: SnackBarBehavior.floating,
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isWishlisted ? Icons.favorite : Icons.favorite_border_rounded,
                                        size: 16,
                                        color: isWishlisted ? const Color(0xFF800020) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF222222),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '₹${(product.discountPrice ?? product.basePrice).toInt()}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF800020),
                                      ),
                                    ),
                                    if (product.discountPrice != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '₹${product.basePrice.toInt()}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD4AF37)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '4.7',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF222222),
                                      ),
                                    ),
                                    Text(
                                      ' (240)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),);
                },
              ),
            ),
          ],
        );
      },
      orElse: () => _buildBestSellersFallbackSection(context),
    );
  }

  Widget _buildBestSellersFallbackSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Best Sellers",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF222222),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  "View All",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF800020),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _bestSellers.length,
            itemBuilder: (context, index) {
              final product = _bestSellers[index];
              final productModel = ProductModel(
                id: product['id'] as String,
                name: product['name'] as String,
                slug: (product['name'] as String).toLowerCase().replaceAll(' ', '-'),
                description: 'A premium-quality fashion piece designed for ultimate style and comfort, crafted from fine breathable fabrics.',
                basePrice: product['price'] as double,
                discountPrice: product['discountPrice'] as double?,
              );
              final productDetails = ProductWithDetails(
                product: productModel,
                imageUrl: product['image'] as String?,
                totalInventory: 20,
                variants: [
                  {'id': 'var-m-${productModel.id}', 'color': 'Beige Cream', 'size': 'M', 'quantity': 10, 'price_adjustment': 0.0},
                  {'id': 'var-l-${productModel.id}', 'color': 'Burgundy Wine', 'size': 'L', 'quantity': 10, 'price_adjustment': 50.0},
                ],
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => context.push('/product-details', extra: productDetails),
                  child: Container(
                    width: 155,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: product['image']!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: const Color(0xFFF5F5F5),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF800020),
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(Icons.error_outline),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF222222),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '₹${product['discountPrice'].toInt()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF800020),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₹${product['price'].toInt()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD4AF37)),
                                const SizedBox(width: 2),
                                Text(
                                  '${product['rating']}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF222222),
                                  ),
                                ),
                                Text(
                                  ' (${product['reviews']})',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: const Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                isActive: true,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                onTap: () {},
              ),
              _buildBottomNavItem(
                isActive: false,
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                label: 'Categories',
                onTap: () => context.pushNamed('categories'),
              ),
              _buildBottomNavItem(
                isActive: false,
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart_rounded,
                label: 'Cart',
                onTap: () => context.pushNamed('cart'),
              ),
              _buildBottomNavItem(
                isActive: false,
                icon: Icons.shopping_bag_outlined,
                activeIcon: Icons.shopping_bag_rounded,
                label: 'Orders',
                onTap: () => context.push('/order-tracking'),
              ),
              _buildBottomNavItem(
                isActive: false,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                onTap: () => context.pushNamed('profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required bool isActive,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF800020).withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? const Color(0xFF800020) : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF800020) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
