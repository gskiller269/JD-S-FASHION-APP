import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/order_model.dart';

class CheckoutController extends GetxController {
  final List<Map<String, dynamic>> checkoutItems;
  final bool isFromCart;

  CheckoutController({
    required this.checkoutItems,
    required this.isFromCart,
  });

  // Steps: 0 = Address, 1 = Payment, 2 = Confirm
  var currentStep = 0.obs;

  // Address Section State
  var userName = 'Jane Doe'.obs;
  var fullAddress = 'Flat 402, Signature Towers, DLF Phase 3, Gurgaon, Haryana - 122002'.obs;
  var mobileNumber = '+91 98765 43210'.obs;

  // Payment Selection State
  var selectedPaymentMethod = 'UPI'.obs;

  // Placement progress
  var isPlacingOrder = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedAddress();
  }

  // Calculate Order Summary
  double get subtotal {
    return checkoutItems.fold(0.0, (sum, item) {
      final price = (item['price'] as num).toDouble();
      final qty = (item['quantity'] as num).toInt();
      return sum + (price * qty);
    });
  }

  int get totalItems {
    return checkoutItems.fold(0, (sum, item) {
      return sum + (item['quantity'] as num).toInt();
    });
  }

  double get shippingFee {
    // Free delivery above 3000
    return subtotal >= 3000 ? 0.0 : 150.0;
  }

  double get discount {
    // 10% premium discount for checkout
    return (subtotal * 0.10).roundToDouble();
  }

  double get finalAmount {
    return subtotal + shippingFee - discount;
  }

  // Address operations
  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('checkout_user_name');
    final savedAddress = prefs.getString('checkout_address');
    final savedPhone = prefs.getString('checkout_phone');

    if (savedName != null) userName.value = savedName;
    if (savedAddress != null) fullAddress.value = savedAddress;
    if (savedPhone != null) mobileNumber.value = savedPhone;
  }

  Future<void> updateAddress(String name, String address, String phone) async {
    userName.value = name;
    fullAddress.value = address;
    mobileNumber.value = phone;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkout_user_name', name);
    await prefs.setString('checkout_address', address);
    await prefs.setString('checkout_phone', phone);
  }

  // Next / Prev step navigation
  void nextStep() {
    if (currentStep.value < 2) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  // Place Order Action
  Future<String?> placeOrder({required VoidCallback onSuccess}) async {
    if (userName.value.trim().isEmpty ||
        fullAddress.value.trim().isEmpty ||
        mobileNumber.value.trim().isEmpty) {
      Get.snackbar(
        'Missing Details',
        'Please provide a complete shipping address.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }

    isPlacingOrder.value = true;
    
    // Simulate payment gateway delay (e.g. UPI authorization, Card verification)
    await Future.delayed(const Duration(seconds: 2));

    try {
      final box = Hive.box('orders_box');
      
      // Auto-generate Order ID: e.g. ORD202600001
      final orderCount = box.length;
      final year = DateTime.now().year;
      final nextOrderNumber = orderCount + 1;
      final formattedNum = nextOrderNumber.toString().padLeft(5, '0');
      final orderId = 'ORD$year$formattedNum';

      // Est. Delivery in 4 days
      final estimatedDelivery = DateTime.now().add(const Duration(days: 4));

      // Choose a delivery partner randomly
      final deliveryPartners = ['Delhivery', 'BlueDart', 'FedEx', 'DHL Express'];
      final deliveryPartner = deliveryPartners[Random().nextInt(deliveryPartners.length)];

      final order = OrderModel(
        orderId: orderId,
        items: checkoutItems.map((item) => OrderItemModel(
          productId: item['productId'] ?? '',
          variantId: item['variantId'] ?? '',
          productName: item['productName'] ?? '',
          quantity: (item['quantity'] as num).toInt(),
          price: (item['price'] as num).toDouble(),
          size: item['size'],
          color: item['color'],
          imageUrl: item['imageUrl'],
        )).toList(),
        deliveryAddress: {
          'name': userName.value,
          'address': fullAddress.value,
          'phone': mobileNumber.value,
        },
        paymentMethod: selectedPaymentMethod.value,
        subtotal: subtotal,
        shippingFee: shippingFee,
        discount: discount,
        totalAmount: finalAmount,
        orderStatus: 'Placed',
        createdAt: DateTime.now(),
        estimatedDeliveryDate: estimatedDelivery,
        deliveryPartner: deliveryPartner,
      );

      // Save to Hive
      await box.put(orderId, order.toMap());

      isPlacingOrder.value = false;
      onSuccess();
      return orderId;
    } catch (e) {
      isPlacingOrder.value = false;
      Get.snackbar(
        'Order Failed',
        'Could not place your order. Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }
  }
}
