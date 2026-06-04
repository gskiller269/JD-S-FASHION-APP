import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/auth_viewmodel.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('login');
    }
  }

  void _signup() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF7A0026),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'You must agree to the Terms & Conditions to create an account.',
            style: GoogleFonts.outfit(color: const Color(0xFFFAF6EE)),
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF7A0026),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Passwords do not match.',
              style: GoogleFonts.outfit(color: const Color(0xFFFAF6EE)),
            ),
          ),
        );
        return;
      }

      final success = await ref.read(authViewModelProvider.notifier).signUp(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            _nameController.text.trim(),
            _phoneController.text.trim(),
          );
      if (success && mounted) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Text(
                'Account created and signed in!',
                style: GoogleFonts.outfit(color: const Color(0xFFFAF6EE)),
              ),
            ),
          );
          context.goNamed('home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Text(
                'Account created! Please check your email or log in.',
                style: GoogleFonts.outfit(color: const Color(0xFFFAF6EE)),
              ),
            ),
          );
          context.goNamed('login');
        }
      } else if (mounted) {
        final error = ref.read(authViewModelProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF7A0026),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Signup failed: ${error.toString()}',
              style: GoogleFonts.outfit(color: const Color(0xFFFAF6EE)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      body: SafeArea(
        child: Center(
          child: isDesktop
              ? Row(
                  children: [
                    // Left Column: Scrollable Signup Form
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: _buildSignupForm(authState, true),
                          ),
                        ),
                      ),
                    ),
                    // Right Column: Full height image banner
                    Expanded(
                      flex: 5,
                      child: _buildImageBanner(),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildMobileHeader(),
                        const SizedBox(height: 32),
                        _buildSignupForm(authState, false),
                        const SizedBox(height: 40),
                        const Divider(color: Color(0xFFEBE3D5), thickness: 1),
                        const SizedBox(height: 24),
                        _buildMobileHighlights(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: _navigateBack,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFEBE3D5), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF7A0026)),
        ),
        const Spacer(),
        // Small hanger logo centered
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF7A0026),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.checkroom_outlined,
            color: Color(0xFFFAF6EE),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "JD'S FASHION",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 2,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildImageBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background soft pink circular graphic to represent circular model background in design
          Positioned(
            right: -100,
            top: 50,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFCEAEB).withOpacity(0.9), // Soft pink circular background
              ),
            ),
          ),
          Image.asset(
            'assets/images/signup_model.png',
            fit: BoxFit.cover,
          ),
          // Dark Luxury Gradient Overlay at the bottom for readability of features
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),
          // Banner Content (Highlights)
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHighlightsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm(AsyncValue<void> authState, bool isDesktop) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop) ...[
            Row(
              children: [
                IconButton(
                  onPressed: _navigateBack,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFEBE3D5), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF7A0026)),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A0026),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.checkroom_outlined,
                    color: Color(0xFFFAF6EE),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "JD'S FASHION",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
          Text(
            'Create Account',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFF1A1A1A),
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Sign up to get started',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A).withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: 36),
          // Name Field
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.outfit(color: const Color(0xFF1A1A1A)),
            decoration: _buildInputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icons.person_outline,
            ),
            validator: (value) =>
                value != null && value.isNotEmpty ? null : 'Enter your full name',
          ),
          const SizedBox(height: 16),
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.outfit(color: const Color(0xFF1A1A1A)),
            decoration: _buildInputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icons.mail_outline,
            ),
            validator: (value) =>
                value != null && value.contains('@') ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 16),
          // Phone Field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.outfit(color: const Color(0xFF1A1A1A)),
            decoration: _buildInputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
            ),
            validator: (value) =>
                value != null && value.length >= 8 ? null : 'Enter a valid phone number',
          ),
          const SizedBox(height: 16),
          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.outfit(color: const Color(0xFF1A1A1A)),
            decoration: _buildInputDecoration(
              labelText: 'Password',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF7A0026).withOpacity(0.7),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) =>
                value != null && value.length >= 6 ? null : 'Password must be 6+ characters',
          ),
          const SizedBox(height: 16),
          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: GoogleFonts.outfit(color: const Color(0xFF1A1A1A)),
            decoration: _buildInputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF7A0026).withOpacity(0.7),
                  size: 20,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirm your password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Terms & Conditions checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _agreeToTerms,
                  activeColor: const Color(0xFF7A0026),
                  side: const BorderSide(color: Color(0xFFEBE3D5), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  children: [
                    Text(
                      'I agree to the ',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1A1A1A).withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Terms & Conditions',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A0026),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      ' & ',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1A1A1A).withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Privacy Policy',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF7A0026),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Sign Up Button
          _buildGradientButton(
            onPressed: authState.isLoading ? null : _signup,
            child: authState.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFAF6EE),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Sign Up',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFFFAF6EE),
                    ),
                  ),
          ),
          const SizedBox(height: 28),
          // Divider "or continue with"
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: const Color(0xFFEBE3D5),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'or continue with',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1A1A1A).withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: const Color(0xFFEBE3D5),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Social Sign In (stacked full width for premium layout)
          _buildSocialButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          _buildGoogleButton(),
          const SizedBox(height: 28),
          // Already have an account? Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A).withOpacity(0.6),
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: _navigateBack,
                child: Text(
                  "Login",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF7A0026),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.outfit(
        color: const Color(0xFF1A1A1A).withOpacity(0.5),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF7A0026).withOpacity(0.7),
        size: 20,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFEBE3D5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF7A0026), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required Widget child,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: onPressed != null
              ? [const Color(0xFF7A0026), const Color(0xFF500018)]
              : [Colors.grey.shade400, Colors.grey.shade500],
        ),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: const Color(0xFF7A0026).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        side: const BorderSide(color: Color(0xFFEBE3D5), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Text(
      "G",
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF4285F4),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        side: const BorderSide(color: Color(0xFFEBE3D5), width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGoogleIcon(),
          const SizedBox(width: 12),
          Text(
            "Continue with Google",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildHighlightItem(Icons.verified_outlined, "Premium Quality"),
          Container(width: 1, height: 24, color: Colors.white.withOpacity(0.2)),
          _buildHighlightItem(Icons.local_offer_outlined, "Best Prices"),
          Container(width: 1, height: 24, color: Colors.white.withOpacity(0.2)),
          _buildHighlightItem(Icons.local_shipping_outlined, "Fast Delivery"),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFFAF6EE), size: 24),
        const SizedBox(height: 6),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: const Color(0xFFFAF6EE),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHighlights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBE3D5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMobileHighlightItem(Icons.verified_outlined, "Premium\nQuality"),
          Container(width: 1, height: 32, color: const Color(0xFFEBE3D5)),
          _buildMobileHighlightItem(Icons.local_offer_outlined, "Best\nPrices"),
          Container(width: 1, height: 32, color: const Color(0xFFEBE3D5)),
          _buildMobileHighlightItem(Icons.local_shipping_outlined, "Fast\nDelivery"),
        ],
      ),
    );
  }

  Widget _buildMobileHighlightItem(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF7A0026), size: 24),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
