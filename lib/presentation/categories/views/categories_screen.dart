import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/viewmodels/home_viewmodel.dart';
import '../../../data/models/category_model.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  // Category display metadata to ensure premium images and counts as requested
  static final Map<String, ({String name, String count, String image})> _categoryMetadata = {
    'shirts': (
      name: 'Shirts',
      count: '120+ Items',
      image: 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=500&q=80'
    ),
    't-shirts': (
      name: 'T-Shirts',
      count: '150+ Items',
      image: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500&q=80'
    ),
    'jeans': (
      name: 'Jeans',
      count: '100+ Items',
      image: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=500&q=80'
    ),
    'jackets': (
      name: 'Jackets',
      count: '80+ Items',
      image: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500&q=80'
    ),
    'trousers': (
      name: 'Trousers',
      count: '90+ Items',
      image: 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=500&q=80'
    ),
    'hoodies': (
      name: 'Hoodies',
      count: '60+ Items',
      image: 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=500&q=80'
    ),
    'shoes': (
      name: 'Footwear',
      count: '120+ Items',
      image: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=500&q=80'
    ),
    'accessories': (
      name: 'Accessories',
      count: '100+ Items',
      image: 'https://images.unsplash.com/photo-1511556532299-8f662fc26c06?w=500&q=80'
    ),
    'watches': (
      name: 'Watches',
      count: '50+ Items',
      image: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=500&q=80'
    ),
    'wallets': (
      name: 'Bags & Wallets',
      count: '40+ Items',
      image: 'https://images.unsplash.com/photo-1627124709702-6c8f6f0491a5?w=500&q=80'
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
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
                // Premium Header Section
                _buildHeader(context),

                // Main Categories Grid
                Expanded(
                  child: categoriesAsync.when(
                    data: (dbCategories) {
                      // Filter and order categories according to the requested order
                      final displayCategories = _prepareCategories(dbCategories);

                      if (displayCategories.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: displayCategories.length,
                        itemBuilder: (context, index) {
                          final category = displayCategories[index];
                          final meta = _categoryMetadata[category.slug];
                          final displayName = meta?.name ?? category.name;
                          final countText = meta?.count ?? 'View Items';
                          final imageUrl = meta?.image ?? category.imageUrl;

                          return _CategoryCard(
                            displayName: displayName,
                            countText: countText,
                            imageUrl: imageUrl,
                            slug: category.slug,
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF800020)),
                      ),
                    ),
                    error: (error, stack) => _buildErrorState(context, ref),
                  ),
                ),

                // Bottom Navigation
                _buildBottomNavigationBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Combine DB categories and align with request. Fallback to DB categories if metadata is missing.
  List<CategoryModel> _prepareCategories(List<CategoryModel> dbCategories) {
    // We order them as requested
    final orderedSlugs = [
      'shirts',
      't-shirts',
      'jeans',
      'jackets',
      'trousers',
      'hoodies',
      'shoes', // Footwear
      'accessories',
      'watches',
      'wallets' // Bags & Wallets
    ];

    final Map<String, CategoryModel> dbMap = {
      for (var cat in dbCategories) cat.slug: cat
    };

    final List<CategoryModel> ordered = [];

    for (var slug in orderedSlugs) {
      if (dbMap.containsKey(slug)) {
        ordered.add(dbMap[slug]!);
      }
    }

    // Add any extra DB categories not in our ordered list
    for (var cat in dbCategories) {
      if (!orderedSlugs.contains(cat.slug)) {
        ordered.add(cat);
      }
    }

    return ordered;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button on left
            IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF222222), size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            // Title
            Text(
              "CATEGORIES",
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
                color: const Color(0xFF222222),
              ),
            ),

            // Search icon on right
            IconButton(
              onPressed: () => context.pushNamed('search'),
              icon: const Icon(Icons.search_rounded, color: Color(0xFF222222), size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view_rounded,
            size: 64,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Categories Available',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF222222),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 50, color: Color(0xFF800020)),
            const SizedBox(height: 16),
            Text(
              'Failed to load categories',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF222222),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(categoriesProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF800020),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
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
                context,
                isActive: false,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                onTap: () => context.go('/'),
              ),
              _buildBottomNavItem(
                context,
                isActive: true,
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                label: 'Categories',
                onTap: () {},
              ),
              _buildBottomNavItem(
                context,
                isActive: false,
                icon: Icons.favorite_outline_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Wishlist',
                onTap: () => context.pushNamed('wishlist'),
              ),
              _buildBottomNavItem(
                context,
                isActive: false,
                icon: Icons.shopping_bag_outlined,
                activeIcon: Icons.shopping_bag_rounded,
                label: 'Orders',
                onTap: () => context.pushNamed('cart'),
              ),
              _buildBottomNavItem(
                context,
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

  Widget _buildBottomNavItem(
    BuildContext context, {
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFF800020) : const Color(0xFF666666),
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? const Color(0xFF800020) : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String displayName;
  final String countText;
  final String? imageUrl;
  final String slug;

  const _CategoryCard({
    required this.displayName,
    required this.countText,
    required this.imageUrl,
    required this.slug,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        context.pushNamed('category', pathParameters: {'slug': widget.slug});
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFF5F5F5),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category Image
                Expanded(
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF9F9F9),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF800020)),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildFallbackBackground(),
                        )
                      : _buildFallbackBackground(),
                ),

                // Category Name & Item Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF222222),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.countText,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: const Color(0xFF888888),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      color: const Color(0xFFF9F9F9),
      child: Center(
        child: Icon(
          Icons.checkroom_rounded,
          size: 32,
          color: const Color(0xFF800020).withOpacity(0.15),
        ),
      ),
    );
  }
}
