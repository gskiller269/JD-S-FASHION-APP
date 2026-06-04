import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/home/views/home_screen.dart';
import '../../presentation/auth/views/login_screen.dart';
import '../../presentation/auth/views/signup_screen.dart';
import '../../presentation/categories/views/categories_screen.dart';
import '../../presentation/cart/views/cart_screen.dart';
import '../../presentation/categories/views/category_screen.dart';
import '../../presentation/auth/viewmodels/auth_viewmodel.dart';
import '../../presentation/splash/views/splash_screen.dart';
import '../../presentation/search/views/search_screen.dart';
import '../../presentation/wishlist/views/wishlist_screen.dart';
import '../../presentation/profile/views/profile_screen.dart';
import '../../presentation/onboarding/views/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider for the router to allow navigation from anywhere using ref
final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // If auth state is still loading, don't redirect yet
      if (authStateAsync.isLoading) return null;

      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup' || isSplash || isOnboarding;

      if (!isAuth && !isLoggingIn) {
        return '/login';
      }

      if (isAuth && isLoggingIn && !isSplash) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/wishlist',
        name: 'wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/category/:slug',
        name: 'category',
        builder: (context, state) => CategoryScreen(
          slug: state.pathParameters['slug']!,
        ),
      ),
    ],
  );
});
