import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';

class UserProfile {
  final String id;
  final String role;
  final String? fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? email;

  UserProfile({
    required this.id,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.email,
  });
}

class UserAddress {
  final String id;
  final String title;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;

  UserAddress({
    required this.id,
    required this.title,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.isDefault,
  });
}

class UserOrder {
  final String id;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String status;
  final String? trackingNumber;
  final DateTime createdAt;

  UserOrder({
    required this.id,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.status,
    this.trackingNumber,
    required this.createdAt,
  });
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseProvider));
});

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  String? get _currentUserId => _supabase.auth.currentUser?.id;
  String? get _currentUserEmail => _supabase.auth.currentUser?.email;

  Future<UserProfile?> getProfile() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;

    return UserProfile(
      id: response['id'] as String,
      role: response['role'] as String,
      fullName: response['full_name'] as String?,
      avatarUrl: response['avatar_url'] as String?,
      phoneNumber: response['phone_number'] as String?,
      email: _currentUserEmail,
    );
  }

  Future<List<UserAddress>> getAddresses() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _supabase
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);

    return (response as List).map((json) {
      return UserAddress(
        id: json['id'] as String,
        title: json['title'] as String,
        addressLine1: json['address_line_1'] as String,
        addressLine2: json['address_line_2'] as String?,
        city: json['city'] as String,
        state: json['state'] as String,
        postalCode: json['postal_code'] as String,
        country: json['country'] as String? ?? 'India',
        isDefault: json['is_default'] as bool? ?? false,
      );
    }).toList();
  }

  Future<List<UserOrder>> getOrders() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await _supabase
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      return UserOrder(
        id: json['id'] as String,
        totalAmount: (json['total_amount'] as num).toDouble(),
        discountAmount: (json['discount_amount'] as num? ?? 0.0).toDouble(),
        finalAmount: (json['final_amount'] as num).toDouble(),
        status: json['status'] as String,
        trackingNumber: json['tracking_number'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    }).toList();
  }
}
