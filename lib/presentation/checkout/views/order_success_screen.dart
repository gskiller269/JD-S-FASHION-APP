import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_theme.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final String paymentMethod;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    // Auto-navigate to Order Tracking after 3 seconds
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToTracking();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToTracking() {
    _timer?.cancel();
    // Navigate to order tracking screen passing the order ID
    context.pushReplacement('/order-tracking', extra: widget.orderId);
  }

  void _continueShopping() {
    _timer?.cancel();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final estDelivery = DateTime.now().add(const Duration(days: 4));
    final formattedEstDate = DateFormat('EEEE, MMM d, yyyy').format(estDelivery);
    final paymentStatus = widget.paymentMethod == 'COD' ? 'Pending (COD)' : 'Paid';

    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Scaffold(
      backgroundColor: isLargeScreen ? const Color(0xFFF5F5F5) : Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Premium Success Animation (Lottie with Circular checkmark fallback)
                SizedBox(
                  height: 180,
                  child: Lottie.network(
                    'https://fonts.gstatic.com/s/a/lottie/success_checkmark.json', // Stable Google Fonts Lottie Asset
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // fallback checkmark animation
                      return Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Placing success message
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Your Order Has Been Placed Successfully',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkAccent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Thank you for styling with JD\'s Fashion',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Order details card
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDetailRow('Order ID', widget.orderId),
                        const Divider(height: 20),
                        _buildDetailRow('Payment Status', paymentStatus,
                            valueColor: widget.paymentMethod == 'COD' ? AppTheme.gold : Colors.green),
                        const Divider(height: 20),
                        _buildDetailRow('Total Amount', '₹${widget.totalAmount.toInt()}'),
                        const Divider(height: 20),
                        _buildDetailRow('Est. Delivery Date', formattedEstDate),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _navigateToTracking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.burgundy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'TRACK ORDER',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _continueShopping,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.burgundy,
                        side: const BorderSide(color: AppTheme.burgundy),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'CONTINUE SHOPPING',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Redirecting to Order Tracking in a few seconds...',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.darkAccent,
          ),
        ),
      ],
    );
  }
}
