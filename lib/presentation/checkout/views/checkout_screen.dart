import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../cart/viewmodels/cart_viewmodel.dart';
import '../controllers/checkout_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> checkoutItems;
  final bool isFromCart;

  const CheckoutScreen({
    super.key,
    required this.checkoutItems,
    this.isFromCart = false,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late CheckoutController controller;
  final String controllerTag = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    // Inject GetX Controller uniquely to avoid collision across entries
    controller = Get.put(
      CheckoutController(
        checkoutItems: widget.checkoutItems,
        isFromCart: widget.isFromCart,
      ),
      tag: controllerTag,
    );
  }

  @override
  void dispose() {
    Get.delete<CheckoutController>(tag: controllerTag);
    super.dispose();
  }

  void _showAddressDialog() {
    final nameCtrl = TextEditingController(text: controller.userName.value);
    final addressCtrl = TextEditingController(text: controller.fullAddress.value);
    final phoneCtrl = TextEditingController(text: controller.mobileNumber.value);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Delivery Address',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressCtrl,
                  decoration: const InputDecoration(labelText: 'Full Address'),
                  maxLines: 3,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Address required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Mobile Number'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                controller.updateAddress(
                  nameCtrl.text.trim(),
                  addressCtrl.text.trim(),
                  phoneCtrl.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      backgroundColor: isLargeScreen ? const Color(0xFFF5F5F5) : Colors.white,
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkAccent,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.darkAccent),
          onPressed: () {
            if (controller.currentStep.value > 0) {
              controller.previousStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                // Animated Stepper Header
                Obx(() => _buildStepIndicator(controller.currentStep.value)),

                // Page content (Address, Payment, Confirm)
                Expanded(
                  child: Obx(() {
                    switch (controller.currentStep.value) {
                      case 0:
                        return _buildAddressStep();
                      case 1:
                        return _buildPaymentStep();
                      case 2:
                        return _buildConfirmStep();
                      default:
                        return _buildAddressStep();
                    }
                  }),
                ),

                // Sticky Bottom Panel
                _buildStickyFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step) {
    final steps = ['Address', 'Payment', 'Confirm'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = index < step;
          final isActive = index == step;
          return Expanded(
            child: Row(
              children: [
                // Step Circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : isActive
                            ? AppTheme.burgundy
                            : Colors.grey.shade200,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                // Step label
                Text(
                  steps[index],
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? AppTheme.burgundy : Colors.grey.shade500,
                  ),
                ),
                // Connector Line
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: index < step ? Colors.green : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Address',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkAccent,
            ),
          ),
          const SizedBox(height: 12),

          // Address Card
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User Name
                      Text(
                        controller.userName.value,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkAccent,
                        ),
                      ),
                      // Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.burgundy.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'HOME',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.burgundy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Full Address
                  Text(
                    controller.fullAddress.value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mobile
                  Row(
                    children: [
                      Icon(Icons.phone_iphone_rounded, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text(
                        controller.mobileNumber.value,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.darkAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Edit Address button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showAddressDialog,
                          icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                          label: Text(
                            'Edit Address',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.burgundy,
                            side: const BorderSide(color: AppTheme.burgundy),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Order Items (${controller.totalItems})',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkAccent,
            ),
          ),
          const SizedBox(height: 12),

          // Items list preview
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.checkoutItems.length,
            itemBuilder: (context, idx) {
              final item = controller.checkoutItems[idx];
              final hasImage = item['imageUrl'] != null;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.burgundy.withOpacity(0.05),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasImage
                            ? CachedNetworkImage(
                                imageUrl: item['imageUrl'],
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.checkroom, color: AppTheme.burgundy),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['productName'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (item['color'] != null)
                                Text('Color: ${item['color']}  ', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                              if (item['size'] != null)
                                Text('Size: ${item['size']}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Qty: ${item['quantity']}',
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                              ),
                              Text(
                                '₹${(item['price'] * item['quantity']).toInt()}',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.burgundy, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    final paymentMethods = [
      {'id': 'UPI', 'name': 'Google Pay / UPI', 'subtitle': 'Instant bank transfer', 'icon': Icons.account_balance_wallet_outlined},
      {'id': 'Card', 'name': 'Credit / Debit Card', 'subtitle': 'Visa, MasterCard, RuPay', 'icon': Icons.credit_card_outlined},
      {'id': 'NetBanking', 'name': 'Net Banking', 'subtitle': 'Direct bank payment', 'icon': Icons.account_balance_outlined},
      {'id': 'COD', 'name': 'Cash On Delivery', 'subtitle': 'Pay cash or scan on delivery', 'icon': Icons.payments_outlined},
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Payment Method',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkAccent,
            ),
          ),
          const SizedBox(height: 16),

          ...paymentMethods.map((method) {
            final isSelected = controller.selectedPaymentMethod.value == method['id'];
            return GestureDetector(
              onTap: () {
                controller.selectedPaymentMethod.value = method['id'] as String;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.burgundy.withOpacity(0.03) : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppTheme.burgundy : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppTheme.burgundy.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  children: [
                    // Payment Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppTheme.burgundy.withOpacity(0.1) : Colors.grey.shade50,
                      ),
                      child: Icon(
                        method['icon'] as IconData,
                        color: isSelected ? AppTheme.burgundy : Colors.grey.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Method Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'] as String,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.darkAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            method['subtitle'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Custom Animated Radio Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.burgundy : Colors.grey.shade400,
                          width: isSelected ? 6 : 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Order',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkAccent,
            ),
          ),
          const SizedBox(height: 16),

          // Order summary block card
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewRow('Shipping To', controller.userName.value, icon: Icons.person_outline),
                  const Divider(height: 24),
                  _buildReviewRow('Address', controller.fullAddress.value, icon: Icons.place_outlined),
                  const Divider(height: 24),
                  _buildReviewRow('Payment Mode', controller.selectedPaymentMethod.value, icon: Icons.payment_outlined),
                  const Divider(height: 24),
                  _buildReviewRow('Items Count', '${controller.totalItems} Items', icon: Icons.shopping_bag_outlined),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Pricing Card
          _buildPricingSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, {required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.burgundy),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkAccent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSummaryCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', '₹${controller.subtotal.toInt()}'),
            const SizedBox(height: 10),
            _buildPriceRow('Delivery Charge', controller.shippingFee == 0 ? 'FREE' : '₹${controller.shippingFee.toInt()}',
                valueColor: controller.shippingFee == 0 ? Colors.green : AppTheme.darkAccent),
            const SizedBox(height: 10),
            _buildPriceRow('Discount (10% Off)', '-₹${controller.discount.toInt()}', valueColor: Colors.green),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Final Amount',
                  style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${controller.finalAmount.toInt()}',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.burgundy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.darkAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
            Obx(() {
              final step = controller.currentStep.value;
              final isPlacing = controller.isPlacingOrder.value;

              if (step < 2) {
                // Address/Payment Proceed button
                return ElevatedButton(
                  onPressed: () => controller.nextStep(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.burgundy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    step == 0 ? 'PROCEED TO PAYMENT' : 'CONFIRM ORDER DETAILS',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
                  ),
                );
              } else {
                // Place Order button
                return ElevatedButton(
                  onPressed: isPlacing
                      ? null
                      : () async {
                          final orderId = await controller.placeOrder(
                            onSuccess: () {
                              // If this order originated from the cart, clear it
                              if (widget.isFromCart) {
                                ref.read(cartProvider.notifier).clearCart();
                              }
                            },
                          );
                          if (orderId != null && context.mounted) {
                            // Navigate to Success screen
                            context.pushReplacement(
                              '/order-success',
                              extra: {
                                'orderId': orderId,
                                'totalAmount': controller.finalAmount,
                                'paymentMethod': controller.selectedPaymentMethod.value,
                              },
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.burgundy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isPlacing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'PLACE ORDER - ₹${controller.finalAmount.toInt()}',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white),
                        ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
