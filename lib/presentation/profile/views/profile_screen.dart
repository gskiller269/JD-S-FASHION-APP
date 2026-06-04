import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

// Profile Future Providers
final profileProvider = FutureProvider<UserProfile?>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});

final addressesProvider = FutureProvider<List<UserAddress>>((ref) {
  return ref.watch(profileRepositoryProvider).getAddresses();
});

final ordersProvider = FutureProvider<List<UserOrder>>((ref) {
  return ref.watch(profileRepositoryProvider).getOrders();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final addressesState = ref.watch(addressesProvider);
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Meta Header Card
            profileState.when(
              data: (profile) => _buildProfileHeader(context, profile),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.burgundy)),
                ),
              ),
              error: (err, stack) => _buildErrorCard('Failed to load profile'),
            ),
            const SizedBox(height: 24),

            // Billing/Shipping Addresses Section
            _buildSectionHeader(context, 'Saved Addresses'),
            const SizedBox(height: 8),
            addressesState.when(
              data: (addresses) => _buildAddressList(context, addresses),
              loading: () => const LinearProgressIndicator(color: AppTheme.burgundy),
              error: (err, stack) => _buildErrorCard('Failed to load addresses'),
            ),
            const SizedBox(height: 24),

            // Order History Section
            _buildSectionHeader(context, 'Recent Orders'),
            const SizedBox(height: 8),
            ordersState.when(
              data: (orders) => _buildOrdersList(context, orders),
              loading: () => const LinearProgressIndicator(color: AppTheme.burgundy),
              error: (err, stack) => _buildErrorCard('Failed to load order history'),
            ),
            const SizedBox(height: 40),

            // Sign out button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out', style: TextStyle(color: AppTheme.burgundy)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(authViewModelProvider.notifier).signOut();
                  // GoRouter will automatically redirect the user to login via ref.watch(authStateProvider)
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.burgundy),
              label: Text(
                'SIGN OUT',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.burgundy,
                side: const BorderSide(color: AppTheme.burgundy),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserProfile? profile) {
    if (profile == null) return _buildErrorCard('User profile not found');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.burgundy.withValues(alpha: 0.1),
            child: Text(
              (profile.fullName ?? profile.email ?? 'JD')[0].toUpperCase(),
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.burgundy,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName ?? 'JD Luxury Guest',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email ?? 'no-email@jdsfashion.com',
                  style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile.role.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildAddressList(BuildContext context, List<UserAddress> addresses) {
    if (addresses.isEmpty) {
      return _buildEmptySection(context, 'No saved addresses');
    }

    return Column(
      children: addresses.map((addr) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: addr.isDefault
                  ? AppTheme.gold.withValues(alpha: 0.5)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: AppTheme.burgundy, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          addr.title,
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        if (addr.isDefault)
                          Text(
                            'DEFAULT',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${addr.addressLine1}${addr.addressLine2 != null ? ", ${addr.addressLine2}" : ""}',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                    ),
                    Text(
                      '${addr.city}, ${addr.state} - ${addr.postalCode}',
                      style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<UserOrder> orders) {
    if (orders.isEmpty) {
      return _buildEmptySection(context, 'No orders placed yet');
    }

    return Column(
      children: orders.map((order) {
        final formattedDate = '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}';
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.burgundy.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.burgundy, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8).toUpperCase()}',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placed on $formattedDate',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${order.finalAmount.toInt()}',
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.burgundy),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptySection(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(
        message,
        style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold),
      ),
    );
  }
}
