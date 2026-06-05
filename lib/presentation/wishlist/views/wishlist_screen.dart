import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/wishlist_repository.dart';
import '../../cart/viewmodels/cart_viewmodel.dart';
import '../controllers/wishlist_controller.dart';
import '../viewmodels/wishlist_viewmodel.dart';
import 'widgets/wishlist_empty_state.dart';
import 'widgets/wishlist_product_card.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  late WishlistController controller;
  late ScrollController _scrollController;
  final String controllerTag = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initialize GetX WishlistController
    controller = Get.put(
      WishlistController(
        wishlistRepository: ref.read(wishlistRepositoryProvider),
        supabaseClient: ref.read(supabaseProvider),
        onRemoveCallback: (productId) {
          // Keep Riverpod in sync
          ref.invalidate(wishlistProvider);
        },
      ),
      tag: controllerTag,
    );

    // Seed initial data from Riverpod if loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final riverpodItems = ref.read(wishlistProvider).value;
      if (riverpodItems != null && riverpodItems.isNotEmpty) {
        controller.wishlistItems.assignAll(riverpodItems);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    Get.delete<WishlistController>(tag: controllerTag);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      controller.loadMoreWishlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in Riverpod's wishlistProvider and update GetX controller state
    ref.listen(wishlistProvider, (previous, next) {
      next.whenData((items) {
        // Only update if there is a mismatch to avoid recursive loops
        if (controller.wishlistItems.length != items.length) {
          controller.wishlistItems.assignAll(items);
        }
      });
    });

    final cartState = ref.watch(cartProvider);
    final cartCount = cartState.value?.length ?? 0;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1.0,
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wishlist',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppTheme.darkAccent,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Obx(() => Text(
                '${controller.wishlistItems.length} items',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              )),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: AppTheme.darkAccent,
                size: 22,
              ),
              onPressed: () {
                context.pushNamed('search');
              },
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppTheme.darkAccent,
                    size: 22,
                  ),
                  onPressed: () {
                    context.pushNamed('cart');
                  },
                ),
                if (cartCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppTheme.burgundy,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$cartCount',
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
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: AppTheme.darkAccent,
                size: 22,
              ),
              onPressed: () {
                Get.snackbar(
                  'Filters',
                  'Sorting and filtering features coming soon!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.white,
                  colorText: AppTheme.darkAccent,
                  duration: const Duration(seconds: 3),
                  margin: const EdgeInsets.all(12),
                  borderRadius: 12,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.wishlistItems.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.burgundy),
              ),
            );
          }

          if (controller.wishlistItems.isEmpty) {
            return WishlistEmptyState(
              onContinueShopping: () {
                context.goNamed('home');
              },
            );
          }

          return RefreshIndicator(
            color: AppTheme.burgundy,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await controller.loadInitialWishlist();
              ref.invalidate(wishlistProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              controller: _scrollController,
              itemCount: controller.wishlistItems.length + (controller.isLoadingMore.value ? 1 : 0),
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey.shade100,
                height: 24,
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                if (index == controller.wishlistItems.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.burgundy),
                      ),
                    ),
                  );
                }
                
                final item = controller.wishlistItems[index];
                return Obx(() => WishlistProductCard(
                  item: item,
                  isRemoving: controller.animatingHeartId.value == item.product.id,
                  onRemove: () async {
                    final name = item.product.name;
                    final removed = await controller.removeFromWishlist(item.product.id);
                    if (removed && context.mounted) {
                      Get.snackbar(
                        'Removed',
                        '$name removed from wishlist',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.black87,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(12),
                        borderRadius: 12,
                      );
                    }
                  },
                  onMoveToCart: () async {
                    final name = item.product.name;
                    final moved = await controller.moveToCart(
                      productId: item.product.id,
                      onAddToCart: (variantId) async {
                        await ref.read(cartProvider.notifier).addItem(variantId, 1);
                      },
                    );
                    
                    if (moved && context.mounted) {
                      Get.snackbar(
                        'Success',
                        'Moved $name to cart successfully!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF2E7D32),
                        colorText: Colors.white,
                        mainButton: TextButton(
                          onPressed: () {
                            context.pushNamed('cart');
                          },
                          child: Text(
                            'VIEW CART',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        margin: const EdgeInsets.all(12),
                        borderRadius: 12,
                      );
                    }
                  },
                  onTap: () async {
                    final details = await controller.getProductDetails(item.product.id, item.imageUrl);
                    if (details != null && context.mounted) {
                      context.push('/product-details', extra: details);
                    }
                  },
                ));
              },
            ),
          );
        }),
      ),
    );
  }
}
