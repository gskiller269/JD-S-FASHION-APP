import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/product_repository.dart';
import '../../cart/viewmodels/cart_viewmodel.dart';
import '../../wishlist/viewmodels/wishlist_viewmodel.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final ProductWithDetails product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _selectedColorIndex = 0;
  int _selectedSizeIndex = 0;
  bool _isAddingToCart = false;


  // Extract unique colors and sizes from variants
  List<String> get _colors {
    final colorsSet = widget.product.variants
        .map((v) => v['color'] as String?)
        .where((c) => c != null && c.isNotEmpty)
        .cast<String>()
        .toSet();
    return colorsSet.toList();
  }

  List<String> get _sizes {
    final sizesSet = widget.product.variants
        .map((v) => v['size'] as String?)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet();
    return sizesSet.toList();
  }

  // Find variant matching selected color & size
  Map<String, dynamic>? get _selectedVariant {
    final colors = _colors;
    final sizes = _sizes;
    if (widget.product.variants.isEmpty) return null;

    final targetColor = colors.isNotEmpty ? colors[_selectedColorIndex] : null;
    final targetSize = sizes.isNotEmpty ? sizes[_selectedSizeIndex] : null;

    try {
      return widget.product.variants.firstWhere(
        (v) {
          final cMatch = targetColor == null || v['color'] == targetColor;
          final sMatch = targetSize == null || v['size'] == targetSize;
          return cMatch && sMatch;
        },
      );
    } catch (_) {
      // Fallback to first available variant
      return widget.product.variants.first;
    }
  }

  Future<void> _handleAddToCart() async {
    final variant = _selectedVariant;
    if (variant == null) return;

    final variantId = variant['id'] as String?;
    if (variantId == null) return;

    setState(() => _isAddingToCart = true);
    try {
      await ref.read(cartProvider.notifier).addItem(variantId, 1);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.product.name} added to cart!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.burgundy,
            action: SnackBarAction(
              label: 'VIEW BAG',
              textColor: AppTheme.cream,
              onPressed: () {
                context.pushNamed('cart');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add to cart: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  void _handleBuyNow() {
    final variant = _selectedVariant;
    if (variant == null) return;

    final variantId = variant['id'] as String?;
    if (variantId == null) return;

    final color = variant['color'] as String?;
    final size = variant['size'] as String?;
    final priceAdjustment = variant['price_adjustment'] as double? ?? 0.0;
    final price = (widget.product.product.discountPrice ?? widget.product.product.basePrice) + priceAdjustment;

    // Create a temporary cart item and pass it to checkout
    final checkoutItem = {
      'productId': widget.product.product.id,
      'variantId': variantId,
      'productName': widget.product.product.name,
      'quantity': 1,
      'price': price,
      'size': size,
      'color': color,
      'imageUrl': widget.product.imageUrl,
    };

    // Navigate to checkout directly, bypassing the shopping cart
    context.push('/checkout', extra: [checkoutItem]);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product.product;
    final hasImage = widget.product.imageUrl != null;
    final basePrice = p.basePrice;
    final discountPrice = p.discountPrice;
    final hasDiscount = discountPrice != null;

    final variant = _selectedVariant;
    final priceAdjustment = variant != null ? (variant['price_adjustment'] as double? ?? 0.0) : 0.0;
    final finalPrice = (discountPrice ?? basePrice) + priceAdjustment;
    final displayBasePrice = basePrice + priceAdjustment;
    
    final discountPercent = hasDiscount
        ? (((displayBasePrice - finalPrice) / displayBasePrice) * 100).round()
        : 0;

    final wishlist = ref.watch(wishlistProvider).value ?? [];
    final isWishlisted = wishlist.any((item) => item.product.id == p.id);

    final colorsList = _colors;
    final sizesList = _sizes;

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
                // Top Custom Header/AppBar
                _buildHeader(context, isWishlisted, p.id),

                // Product Details Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Large Product Photo with Hero Animation
                        Hero(
                          tag: 'product_image_${p.id}',
                          child: AspectRatio(
                            aspectRatio: 0.85,
                            child: hasImage
                                ? CachedNetworkImage(
                                    imageUrl: widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: const Color(0xFFF9F9F9),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.burgundy),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                                  )
                                : Container(
                                    color: const Color(0xFFF5F5F5),
                                    child: const Icon(Icons.image, size: 80, color: Colors.grey),
                                  ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Brand Label
                              Text(
                                "JD'S COLLECTION",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.burgundy,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Product Title
                              Text(
                                p.name,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkAccent,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Pricing Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '₹${finalPrice.toInt()}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.burgundy,
                                    ),
                                  ),
                                  if (hasDiscount) ...[
                                    const SizedBox(width: 10),
                                    Text(
                                      '₹${displayBasePrice.toInt()}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '($discountPercent% OFF)',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: AppTheme.gold,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "inclusive of all taxes",
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),

                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                              ),

                              // Color Selection
                              if (colorsList.isNotEmpty) ...[
                                Text(
                                  "SELECT COLOR",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkAccent,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 40,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: colorsList.length,
                                    itemBuilder: (context, index) {
                                      final colorName = colorsList[index];
                                      final isSelected = _selectedColorIndex == index;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedColorIndex = index),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          margin: const EdgeInsets.only(right: 12),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppTheme.burgundy : Colors.white,
                                            border: Border.all(
                                              color: isSelected ? AppTheme.burgundy : Colors.grey.shade300,
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Center(
                                            child: Text(
                                              colorName,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Size Selection
                              if (sizesList.isNotEmpty) ...[
                                Text(
                                  "SELECT SIZE",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkAccent,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 48,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: sizesList.length,
                                    itemBuilder: (context, index) {
                                      final sizeName = sizesList[index];
                                      final isSelected = _selectedSizeIndex == index;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedSizeIndex = index),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          margin: const EdgeInsets.only(right: 12),
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppTheme.burgundy : Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? AppTheme.burgundy : Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              sizeName,
                                              style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Description Section
                              Text(
                                "PRODUCT DETAILS",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkAccent,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                p.description,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Features row
                              _buildFeaturesSummary(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Actions
                _buildBottomActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isWishlisted, String productId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.darkAccent, size: 20),
            ),
            Text(
              "PRODUCT DETAILS",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: AppTheme.darkAccent,
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(wishlistProvider.notifier).toggleWishlist(productId);
              },
              icon: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border_rounded,
                color: isWishlisted ? AppTheme.burgundy : AppTheme.darkAccent,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFeatureIcon(Icons.verified, "100% Original"),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildFeatureIcon(Icons.swap_horizontal_circle, "Easy Returns"),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildFeatureIcon(Icons.local_shipping, "Free Shipping"),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.burgundy, size: 20),
        const SizedBox(height: 6),
        Text(
          text,
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
        )
      ],
    );
  }

  Widget _buildBottomActionButtons(BuildContext context) {
    final isOutOfStock = widget.product.totalInventory <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Add To Bag Button
            Expanded(
              child: OutlinedButton(
                onPressed: (isOutOfStock || _isAddingToCart) ? null : _handleAddToCart,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: AppTheme.burgundy, width: 1.5),
                ),
                child: _isAddingToCart
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.burgundy),
                        ),
                      )
                    : Text(
                        isOutOfStock ? "OUT OF STOCK" : "ADD TO BAG",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.burgundy,
                          letterSpacing: 1.0,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Buy Now Button
            Expanded(
              child: ElevatedButton(
                onPressed: isOutOfStock ? null : _handleBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.burgundy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                child: Text(
                  "BUY NOW",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
