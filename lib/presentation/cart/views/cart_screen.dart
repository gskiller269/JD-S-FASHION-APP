import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../../../data/repositories/cart_repository.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Bag',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          if (cartState.value != null && cartState.value!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.burgundy),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Shopping Bag?'),
                    content: const Text('Are you sure you want to remove all items from your bag?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          cartNotifier.clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear', style: TextStyle(color: AppTheme.burgundy)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartState.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.burgundy.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: AppTheme.burgundy,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your bag is empty',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add premium pieces to start styling your look',
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _CartItemRow(item: item);
                  },
                ),
              ),
              _buildCheckoutPanel(context, ref),
            ],
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
                'Failed to load cart',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(cartProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutPanel(BuildContext context, WidgetRef ref) {
    final subtotal = ref.read(cartProvider.notifier).subtotal;
    final shippingFee = subtotal >= 3000 ? 0.0 : 150.0;
    final total = subtotal + shippingFee;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '₹${subtotal.toInt()}',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Charge',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  shippingFee == 0.0 ? 'FREE' : '₹${shippingFee.toInt()}',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: shippingFee == 0.0 ? Colors.green : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (shippingFee > 0.0) ...[
              const SizedBox(height: 4),
              Text(
                'Add pieces worth ₹${(3000 - subtotal).toInt()} more for FREE delivery',
                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.gold, fontWeight: FontWeight.w500),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${total.toInt()}',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.burgundy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final items = ref.read(cartProvider).value ?? [];
                if (items.isEmpty) return;

                final checkoutItems = items.map((item) => {
                  'productId': item.productId,
                  'variantId': item.variantId,
                  'productName': item.productName,
                  'quantity': item.quantity,
                  'price': item.price,
                  'size': item.size,
                  'color': item.color,
                  'imageUrl': item.imageUrl,
                }).toList();

                context.push('/checkout?fromCart=true', extra: checkoutItems);
              },
              child: Text(
                'PROCEED TO CHECKOUT',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends ConsumerWidget {
  final CartItemWithProduct item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final totalItemPrice = item.price * item.quantity;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C2C2C)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image thumbnail
          Container(
            width: 80,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.burgundy.withValues(alpha: 0.1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasImage
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildFallbackThumbnail(),
                    )
                  : _buildFallbackThumbnail(),
            ),
          ),
          const SizedBox(width: 16),
          // Product details & Quantity controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () {
                        ref.read(cartProvider.notifier).removeItem(item.id);
                      },
                    ),
                  ],
                ),
                // Size and Color info
                if (item.color != null || item.size != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (item.color != null)
                        Text(
                          'Color: ${item.color}',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                        ),
                      if (item.color != null && item.size != null)
                        const Text('  |  ', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      if (item.size != null)
                        Text(
                          'Size: ${item.size}',
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity adjuster controls
                    Row(
                      children: [
                        _buildQuantityButton(
                          icon: Icons.remove,
                          onTap: () {
                            ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '${item.quantity}',
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildQuantityButton(
                          icon: Icons.add,
                          onTap: () {
                            ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1);
                          },
                        ),
                      ],
                    ),
                    // Item Total Price
                    Text(
                      '₹${totalItemPrice.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.burgundy,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.black54),
      ),
    );
  }

  Widget _buildFallbackThumbnail() {
    return Center(
      child: Icon(
        Icons.checkroom,
        size: 28,
        color: AppTheme.burgundy.withValues(alpha: 0.4),
      ),
    );
  }
}
