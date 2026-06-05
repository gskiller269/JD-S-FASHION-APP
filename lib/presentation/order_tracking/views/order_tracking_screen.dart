import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/order_tracking_controller.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderId;

  const OrderTrackingScreen({
    super.key,
    this.orderId,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderTrackingController controller;
  final String controllerTag = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    // Inject GetX Controller uniquely to avoid collision across entries
    controller = Get.put(
      OrderTrackingController(initialOrderId: widget.orderId),
      tag: controllerTag,
    );
  }

  @override
  void dispose() {
    Get.delete<OrderTrackingController>(tag: controllerTag);
    super.dispose();
  }

  void _showOrderHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Track Another Order',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Obx(() {
          if (controller.allOrders.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No orders found in history.', textAlign: TextAlign.center),
            );
          }

          return SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: controller.allOrders.length,
              itemBuilder: (context, index) {
                final o = controller.allOrders[index];
                final dateStr = DateFormat('MMM d, yyyy').format(o.createdAt);
                return ListTile(
                  title: Text(
                    'Order #${o.orderId}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Date: $dateStr • ₹${o.totalAmount.toInt()}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: o.orderStatus == 'Delivered' ? Colors.green.withOpacity(0.08) : AppTheme.burgundy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      o.orderStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: o.orderStatus == 'Delivered' ? Colors.green : AppTheme.burgundy,
                      ),
                    ),
                  ),
                  onTap: () {
                    // Update controller with new order ID
                    Navigator.pop(context);
                    // Open a new screen or update state
                    Get.delete<OrderTrackingController>(tag: controllerTag);
                    controller = Get.put(
                      OrderTrackingController(initialOrderId: o.orderId),
                      tag: controllerTag,
                    );
                    setState(() {});
                  },
                );
              },
            ),
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Customer Support',
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF5F5F5)),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.burgundy),
                ),
                title: const Text('Chat with an Expert'),
                subtitle: const Text('Available 24/7'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support Chat starting...')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF5F5F5)),
                  child: const Icon(Icons.phone_outlined, color: AppTheme.burgundy),
                ),
                title: const Text('Call Helpline'),
                subtitle: const Text('Toll Free: 1800-123-4567'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calling support...')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadInvoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading Invoice... PDF will be saved to your device.'),
        backgroundColor: Colors.green,
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
          'Order Tracking',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkAccent,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.darkAccent),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            color: Colors.white,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.burgundy),
                  ),
                );
              }

              final order = controller.order.value;
              if (order == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No Order Tracked',
                          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You don\'t have any placed orders to track right now.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _showOrderHistoryDialog,
                          child: const Text('View Order History'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final formattedDate = DateFormat('MMM d, yyyy').format(order.createdAt);
              final formattedEstDate = DateFormat('MMM d, yyyy').format(order.estimatedDeliveryDate);

              return RefreshIndicator(
                onRefresh: controller.refreshOrder,
                color: AppTheme.burgundy,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Header Card
                      _buildStatusCard(order, formattedEstDate),

                      // Animated Horizontal Stepper Timeline
                      _buildHorizontalTimeline(),

                      // Order Items Section
                      _buildOrderItemsSection(order),

                      // Delivery & Partner Info
                      _buildDeliveryInfoSection(order, formattedDate),

                      // Actions Block
                      _buildActionButtons(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(order, String estArrival) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID: #${order.orderId}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.orderStatus == 'Delivered' ? 'Delivered' : 'Arriving by $estArrival',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: order.orderStatus == 'Delivered' ? Colors.green : AppTheme.gold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${order.orderStatus}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: order.orderStatus == 'Delivered' ? Colors.green : AppTheme.gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Graphic status thumbnail
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.burgundy.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              order.orderStatus == 'Delivered'
                  ? Icons.check_circle_outline_rounded
                  : Icons.local_shipping_outlined,
              color: AppTheme.burgundy,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline() {
    final currentIdx = controller.currentStatusIndex;
    final timelineSteps = ['Placed', 'Confirmed', 'Packed', 'Shipped', 'Out', 'Delivered'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Tracking Journey',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkAccent,
              ),
            ),
          ),
          // Custom horizontal progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(timelineSteps.length, (index) {
              final isCompleted = index < currentIdx;
              final isCurrent = index == currentIdx;


              return Expanded(
                child: Row(
                  children: [
                    // Node
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? Colors.green
                                : isCurrent
                                    ? AppTheme.burgundy
                                    : Colors.grey.shade200,
                            border: isCurrent
                                ? Border.all(color: AppTheme.burgundy.withOpacity(0.2), width: 4)
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 10, color: Colors.white)
                                : isCurrent
                                    ? const Center(
                                        child: SizedBox(
                                          width: 6,
                                          height: 6,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey,
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          timelineSteps[index],
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent
                                ? AppTheme.burgundy
                                : isCompleted
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    // Connector line (except for last element)
                    if (index < timelineSteps.length - 1)
                      Expanded(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 3,
                              color: isCompleted ? Colors.green : Colors.grey.shade200,
                            ),
                            const SizedBox(height: 15), // align with circle height offset
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Divider(height: 24, color: Color(0xFFF5F5F5)),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(order) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items in Shipment',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkAccent,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            itemBuilder: (context, index) {
              final item = order.items[index];
              final hasImage = item.imageUrl != null;
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
                      width: 50,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.burgundy.withOpacity(0.05),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasImage
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
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
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (item.color != null)
                                Text('Color: ${item.color}  ', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                              if (item.size != null)
                                Text('Size: ${item.size}', style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quantity: ${item.quantity}',
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                '₹${item.price.toInt()}',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.burgundy, fontSize: 13),
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
          const Divider(height: 24, color: Color(0xFFF5F5F5)),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoSection(order, String formattedDate) {
    final shippingAddress = order.deliveryAddress['address'] ?? '';
    final recipientName = order.deliveryAddress['name'] ?? '';
    final phone = order.deliveryAddress['phone'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipment Details',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkAccent,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildDetailsInfoRow('Delivery Address', '$recipientName\n$shippingAddress', icon: Icons.place_outlined),
                  const Divider(height: 24),
                  _buildDetailsInfoRow('Contact Number', phone, icon: Icons.phone_android_outlined),
                  const Divider(height: 24),
                  _buildDetailsInfoRow('Shipping Carrier', order.deliveryPartner, icon: Icons.local_shipping_outlined),
                  const Divider(height: 24),
                  _buildDetailsInfoRow('Order Date', formattedDate, icon: Icons.calendar_month_outlined),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailsInfoRow(String title, String val, {required IconData icon}) {
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
                title,
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                val,
                style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.darkAccent, fontWeight: FontWeight.w600, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSupportBottomSheet,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text('Contact Support', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.burgundy,
                    side: const BorderSide(color: AppTheme.burgundy),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadInvoice,
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: Text('Download Invoice', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.burgundy,
                    side: const BorderSide(color: AppTheme.burgundy),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showOrderHistoryDialog,
            icon: const Icon(Icons.history_rounded, size: 16, color: Colors.white),
            label: Text(
              'TRACK ANOTHER ORDER',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.burgundy,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
