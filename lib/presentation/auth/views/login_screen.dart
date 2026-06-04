import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../../data/repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authViewModelProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!success && mounted) {
        final error = ref.read(authViewModelProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF7A0026),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Login failed: ${error.toString()}',
              style: GoogleFonts.outfit(color: const Color(0xFFFAF6EE)),
            ),
          ),
        );
      }
    }
  }

  void _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF7A0026),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'Please enter a valid email address to reset your password.',
            style: GoogleFonts.outfit(color: const Color(0xFFFAF6EE)),
          ),
        ),
      );
      return;
    }
    
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Password reset email sent!',
              style: GoogleFonts.outfit(color: const Color(0xFFFAF6EE)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF7A0026),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Error: ${e.toString()}',
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
                    // Left Column: Full height image banner
                    Expanded(
                      flex: 5,
                      child: _buildImageBanner(),
                    ),
                    // Right Column: Centered Login Form
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 32.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 450),
                            child: _buildLoginForm(authState, true),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Mobile Header Image Banner
                      _buildMobileHeader(),
                      // Mobile Login Form
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                        child: _buildLoginForm(authState, false),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildImageBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
          Image.asset(
            'assets/images/login_model.png',
            fit: BoxFit.cover,
          ),
          // Dark Luxury Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          // Banner Content
          Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                        color: const Color(0xFFFAF6EE),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  "Style That\nDefines You",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFAF6EE),
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Premium quality men's fashion, crafted for you",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFAF6EE).withOpacity(0.85),
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_model.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.2),
          ),
          // Dark Luxury Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
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
                        color: const Color(0xFFFAF6EE),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Style That Defines You",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFAF6EE),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Premium quality men's fashion, crafted for you",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFAF6EE).withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(AsyncValue<void> authState, bool isDesktop) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isDesktop) ...[
            // Minimal Hanger Logo Centered
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7A0026),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7A0026).withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.checkroom_outlined,
                      color: Color(0xFFFAF6EE),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "JD'S FASHION",
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
          Text(
            'Welcome Back!',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFF1A1A1A),
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Login to continue',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A).withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),
          const SizedBox(height: 36),
          // Email field
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
          const SizedBox(height: 18),
          // Password field
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
          const SizedBox(height: 12),
          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF7A0026),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Burgundy Gradient Login Button
          _buildGradientButton(
            onPressed: authState.isLoading ? null : _login,
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
                    'Login',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFFFAF6EE),
                    ),
                  ),
          ),
          const SizedBox(height: 32),
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
          const SizedBox(height: 24),
          // Social Sign In (stacked full width for premium layout)
          _buildSocialButton(
            icon: Icons.apple,
            label: 'Continue with Apple',
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          _buildGoogleButton(),
          const SizedBox(height: 32),
          // Don't have an account? Sign Up
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A).withOpacity(0.6),
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () => context.pushNamed('signup'),
                child: Text(
                  "Sign Up",
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
}
