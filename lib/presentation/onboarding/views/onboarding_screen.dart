import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.1, 0.7, curve: Curves.easeOut)),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToSignup() {
    context.goNamed('signup');
  }

  void _navigateToLogin() {
    context.goNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Section - Logo & Branding
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Column(
                      children: [
                        Text(
                          "JD's",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.burgundy,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          "FASHION",
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.burgundy,
                            letterSpacing: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Hero Section - Model Image with circular background
                Expanded(
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Center(
                        child: SizedBox(
                          height: size.height * 0.38,
                          child: Image.asset(
                            'assets/images/onboarding_model.png',
                            fit: BoxFit.contain,
                            height: size.height * 0.38,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Info & CTA Bottom Group
                Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Headline
                          Text(
                            "Look Good, Feel Great",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF222222), // Dark Text
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Subheading
                          Text(
                            "Find the latest trends, exclusive collections and style that defines you.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              height: 1.5,
                              color: const Color(0xFF888888), // Light Gray
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Pagination Dots (Second dot active)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isActive = index == 1; // 2nd dot is active
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                width: isActive ? 24.0 : 8.0,
                                height: 8.0,
                                decoration: BoxDecoration(
                                  color: isActive ? AppTheme.burgundy : const Color(0xFFD3D3D3),
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 32),

                          // Full-Width Rounded CTA Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.0),
                              gradient: const LinearGradient(
                                colors: [AppTheme.burgundy, Color(0xFF4A0010)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.burgundy.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _navigateToSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 18.0),
                              ),
                              child: Text(
                                "Get Started",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Footer Navigation Text
                          GestureDetector(
                            onTap: _navigateToLogin,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: const Color(0xFF888888),
                                  ),
                                  children: [
                                    const TextSpan(text: "Already have an account? "),
                                    TextSpan(
                                      text: "Login",
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.burgundy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
