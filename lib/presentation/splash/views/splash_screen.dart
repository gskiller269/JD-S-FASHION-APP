import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _arrowController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Logo Fade Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // 2. Logo Scale Animation (Breathing/Slight Zoom)
    _scaleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.03).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    // 3. Arrow bouncing animation for CTA
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _arrowAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();

    // Auto navigate after 3 seconds
    Timer(const Duration(seconds: 3), _navigateToNextScreen);
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      context.goNamed('home');
    } else {
      context.goNamed('onboarding');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Wine/Burgundy Radial Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Color(0xFF8A0030), // Soft center wine glow
                    Color(0xFF5B001A), // Deep outer burgundy
                  ],
                ),
              ),
            ),
          ),

          // Ambient soft glow overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.6,
                  colors: [
                    const Color(0xFFD4AF37).withValues(alpha: 0.04), // Warm gold highlight glow
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Scattered low-opacity fashion outline icons
          Positioned.fill(
            child: Stack(
              children: [
                _buildScatteredIcon(Icons.checkroom_outlined, top: 0.12, left: 0.15, size: 36, rotation: 0.2),
                _buildScatteredIcon(Icons.dry_cleaning_outlined, top: 0.08, right: 0.22, size: 28, rotation: -0.15),
                _buildScatteredIcon(Icons.shopping_bag_outlined, top: 0.26, right: 0.12, size: 34, rotation: 0.1),
                _buildScatteredIcon(Icons.watch_outlined, top: 0.35, left: 0.08, size: 30, rotation: -0.25),
                _buildScatteredIcon(Icons.diamond_outlined, bottom: 0.38, right: 0.15, size: 26, rotation: 0.3),
                _buildScatteredIcon(Icons.style_outlined, bottom: 0.28, left: 0.20, size: 32, rotation: -0.05),
                _buildScatteredIcon(Icons.checkroom_rounded, bottom: 0.12, left: 0.10, size: 38, rotation: 0.15),
                _buildScatteredIcon(Icons.store_outlined, bottom: 0.09, right: 0.18, size: 32, rotation: -0.1),
              ],
            ),
          ),

          // Branding and CTA Layout
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40), // Spacing at top

                  // Center Logo & Tagline Group
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gold Clothes Hanger Icon
                      Icon(
                        Icons.checkroom_rounded,
                        size: 52,
                        color: AppTheme.gold.withValues(alpha: 0.95),
                      ),
                      const SizedBox(height: 12),

                      // Large Elegant White Serif Logo
                      Text(
                        "JD's",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 68,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      
                      // Spaced uppercase FASHION
                      Text(
                        "FASHION",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 10,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tagline
                      Text(
                        "Style that defines you ❤️",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),

                  // Bottom CTA
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Center(
                      child: GestureDetector(
                        onTap: _navigateToNextScreen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          color: Colors.transparent, // Ensures easy tapping
                          child: AnimatedBuilder(
                            animation: _arrowAnimation,
                            builder: (context, child) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Let's Style You",
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: Offset(_arrowAnimation.value, 0),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Scattered background outline icons utility
  Widget _buildScatteredIcon(
    IconData icon, {
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required double rotation,
  }) {
    return Positioned(
      top: top != null ? MediaQuery.of(context).size.height * top : null,
      bottom: bottom != null ? MediaQuery.of(context).size.height * bottom : null,
      left: left != null ? MediaQuery.of(context).size.width * left : null,
      right: right != null ? MediaQuery.of(context).size.width * right : null,
      child: Transform.rotate(
        angle: rotation,
        child: Icon(
          icon,
          size: size,
          color: Colors.white.withValues(alpha: 0.06), // Thin outline with 6% opacity
        ),
      ),
    );
  }
}
