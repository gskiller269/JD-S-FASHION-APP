import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final SupabaseClient _supabase = Supabase.instance.client;

  var isLoading = true.obs;

  // Profile fields (reactive)
  var userName = 'Jane Doe'.obs;
  var userEmail = 'jane.doe@jdsfashion.com'.obs;
  var userPhone = '+91 98765 43210'.obs;
  var userAvatarUrl = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80'.obs;
  var userRole = 'Luxury Member'.obs;

  // Premium avatar options
  final List<String> avatarOptions = [
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80', // Female 1
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200&q=80', // Male 1
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80', // Female 2
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80', // Male 2
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80', // Female 3
  ];

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      // 1. Try loading from local SharedPreferences first (fast cache)
      final prefs = await SharedPreferences.getInstance();
      final localName = prefs.getString('profile_user_name');
      final localEmail = prefs.getString('profile_user_email');
      final localPhone = prefs.getString('profile_user_phone');
      final localAvatar = prefs.getString('profile_avatar_url');

      if (localName != null) userName.value = localName;
      if (localEmail != null) userEmail.value = localEmail;
      if (localPhone != null) userPhone.value = localPhone;
      if (localAvatar != null) userAvatarUrl.value = localAvatar;

      // 2. Fetch from Supabase as backend source of truth
      final userId = _supabase.auth.currentUser?.id;
      final authEmail = _supabase.auth.currentUser?.email;
      if (authEmail != null && localEmail == null) {
        userEmail.value = authEmail;
      }

      if (userId != null) {
        final profileResponse = await _supabase
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (profileResponse != null) {
          final dbName = profileResponse['full_name'] as String?;
          final dbPhone = profileResponse['phone_number'] as String?;
          final dbAvatar = profileResponse['avatar_url'] as String?;
          final dbRole = profileResponse['role'] as String? ?? 'Luxury Member';

          if (dbName != null && dbName.isNotEmpty) userName.value = dbName;
          if (dbPhone != null && dbPhone.isNotEmpty) userPhone.value = dbPhone;
          if (dbAvatar != null && dbAvatar.isNotEmpty) userAvatarUrl.value = dbAvatar;
          userRole.value = dbRole;

          // Save to local cache
          await prefs.setString('profile_user_name', userName.value);
          await prefs.setString('profile_user_phone', userPhone.value);
          await prefs.setString('profile_avatar_url', userAvatarUrl.value);
        }
      }
    } catch (e) {
      print('Profile fetch error fallback to cache: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfileInfo(String name, String email, String phone) async {
    isLoading.value = true;
    try {
      userName.value = name;
      userEmail.value = email;
      userPhone.value = phone;

      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_user_name', name);
      await prefs.setString('profile_user_email', email);
      await prefs.setString('profile_user_phone', phone);

      // Sync backend
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('profiles').update({
          'full_name': name,
          'phone_number': phone,
        }).eq('id', userId);
      }

      Get.snackbar(
        'Success',
        'Profile updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      print('Sync profile error: $e');
      Get.snackbar(
        'Warning',
        'Profile updated locally, but failed to sync backend: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.shade700,
        colorText: Colors.white,
      );
      return true; // Return true as local update succeeded
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateAvatar(String newAvatarUrl) async {
    userAvatarUrl.value = newAvatarUrl;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_avatar_url', newAvatarUrl);

      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        await _supabase.from('profiles').update({
          'avatar_url': newAvatarUrl,
        }).eq('id', userId);
      }
    } catch (e) {
      print('Avatar sync error: $e');
    }
  }
}
