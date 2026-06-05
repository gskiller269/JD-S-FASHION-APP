import 'dart:async';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/order_model.dart';

class OrderTrackingController extends GetxController {
  final String? initialOrderId;

  OrderTrackingController({this.initialOrderId});

  var isLoading = true.obs;
  var order = Rxn<OrderModel>();
  var allOrders = <OrderModel>[].obs;
  
  // Real-time status list
  final List<String> statuses = [
    'Placed',
    'Confirmed',
    'Packed',
    'Shipped',
    'Out For Delivery',
    'Delivered'
  ];

  Timer? _simulationTimer;

  @override
  void onInit() {
    super.onInit();
    loadOrderDetails();
  }

  @override
  void onClose() {
    _simulationTimer?.cancel();
    super.onClose();
  }

  // Load order details from Hive
  Future<void> loadOrderDetails() async {
    isLoading.value = true;
    _simulationTimer?.cancel();

    try {
      final box = Hive.box('orders_box');
      
      // Load all orders for history / switching
      final allOrderKeys = box.keys.toList();
      final List<OrderModel> ordersList = [];
      for (var key in allOrderKeys) {
        final data = box.get(key);
        if (data != null) {
          ordersList.add(OrderModel.fromMap(Map<String, dynamic>.from(data)));
        }
      }
      // Sort orders by date descending
      ordersList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      allOrders.value = ordersList;

      String? targetOrderId = initialOrderId;
      
      // If no order ID provided, load the latest placed order
      if ((targetOrderId == null || targetOrderId.isEmpty) && ordersList.isNotEmpty) {
        targetOrderId = ordersList.first.orderId;
      }

      if (targetOrderId != null && targetOrderId.isNotEmpty) {
        final data = box.get(targetOrderId);
        if (data != null) {
          order.value = OrderModel.fromMap(Map<String, dynamic>.from(data));
          
          // Save last tracked order ID to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_tracked_order_id', targetOrderId);

          // Start status simulation if not already delivered
          if (order.value!.orderStatus != 'Delivered') {
            _startStatusSimulation();
          }
        } else {
          order.value = null;
        }
      } else {
        order.value = null;
      }
    } catch (e) {
      print('Error loading order tracking: $e');
      order.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  // Simulate real-time tracking updates (Placed -> Confirmed -> Packed -> Shipped -> Out For Delivery -> Delivered)
  void _startStatusSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      if (order.value == null) return;

      final currentStatus = order.value!.orderStatus;
      final currentIndex = statuses.indexOf(currentStatus);

      if (currentIndex != -1 && currentIndex < statuses.length - 1) {
        final nextStatus = statuses[currentIndex + 1];
        
        // Update model locally
        final updatedOrder = OrderModel(
          orderId: order.value!.orderId,
          items: order.value!.items,
          deliveryAddress: order.value!.deliveryAddress,
          paymentMethod: order.value!.paymentMethod,
          subtotal: order.value!.subtotal,
          shippingFee: order.value!.shippingFee,
          discount: order.value!.discount,
          totalAmount: order.value!.totalAmount,
          orderStatus: nextStatus,
          createdAt: order.value!.createdAt,
          estimatedDeliveryDate: order.value!.estimatedDeliveryDate,
          deliveryPartner: order.value!.deliveryPartner,
        );

        order.value = updatedOrder;

        // Persist update in Hive
        final box = Hive.box('orders_box');
        await box.put(order.value!.orderId, updatedOrder.toMap());

        // Also update allOrders list
        final indexInList = allOrders.indexWhere((o) => o.orderId == order.value!.orderId);
        if (indexInList != -1) {
          allOrders[indexInList] = updatedOrder;
        }

        // Notify user about update via snackbar
        Get.snackbar(
          'Order Status Update',
          'Order #${order.value!.orderId} is now "$nextStatus".',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );

        if (nextStatus == 'Delivered') {
          _simulationTimer?.cancel();
        }
      } else {
        _simulationTimer?.cancel();
      }
    });
  }

  // Reload current order
  Future<void> refreshOrder() async {
    if (order.value != null) {
      final box = Hive.box('orders_box');
      final data = box.get(order.value!.orderId);
      if (data != null) {
        order.value = OrderModel.fromMap(Map<String, dynamic>.from(data));
      }
    }
  }

  // Get index of the current status
  int get currentStatusIndex {
    if (order.value == null) return 0;
    return statuses.indexOf(order.value!.orderStatus);
  }
}
