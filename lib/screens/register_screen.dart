import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  final List<Color> _gradientColors = [
    const Color(0xFF0A1172), // Deep Ethiopian Night
    const Color(0xFF4527A0), // Royal Amethyst
    const Color(0xFF1A237E), // Midnight Indigo
    const Color(0xFF512DA8), // Ethiopian Twilight
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context
                    .read<LanguageProvider>()
                    .translate('accept_terms_error')),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Registration successful!')),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      // Navigate to login screen after successful registration
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(e.toString())),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildFloatingParticle(double x, double y, double size) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(size),
        ),
      )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .moveY(
            duration: Duration(seconds: 3 + (x * 0.1).round()),
            begin: y - 30,
            end: y + 30,
            curve: Curves.easeInOut,
          )
          .fadeIn(duration: const Duration(milliseconds: 600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(_gradientColors[0], _gradientColors[1],
                              _backgroundAnimation.value) ??
                          _gradientColors[0],
                      Color.lerp(_gradientColors[2], _gradientColors[3],
                              _backgroundAnimation.value) ??
                          _gradientColors[2],
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating particles
          ...[
            _buildFloatingParticle(size.width * 0.15, size.height * 0.2, 5),
            _buildFloatingParticle(size.width * 0.85, size.height * 0.3, 4),
            _buildFloatingParticle(size.width * 0.45, size.height * 0.5, 6),
            _buildFloatingParticle(size.width * 0.75, size.height * 0.7, 3),
            _buildFloatingParticle(size.width * 0.25, size.height * 0.8, 5),
          ],

          // Main content
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Back button with elegant animation
                    FadeInLeft(
                      duration: const Duration(milliseconds: 600),
                      child: IconButton.filled(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ).animate(
                        effects: [
                          ShimmerEffect(
                            duration: const Duration(seconds: 3),
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Header section with enhanced animations
                    FadeInDown(
                      duration: const Duration(milliseconds: 800),
                      child: Column(
                        children: [
                          // Modern app logo/icon
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.account_circle_outlined,
                              size: 40,
                              color: Colors.white,
                            ),
                          ).animate(
                            effects: [
                              ShimmerEffect(
                                duration: const Duration(seconds: 3),
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            lang.translate('create_account'),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ).animate(
                            effects: [
                              const FadeEffect(
                                  duration: Duration(milliseconds: 800)),
                              const SlideEffect(
                                begin: Offset(0, 0.3),
                                curve: Curves.easeOutQuart,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.translate('register_subtitle'),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: -0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Registration Form with glassmorphism
                    FadeInUp(
                      duration: const Duration(milliseconds: 1000),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildTextField(
                                    controller: _usernameController,
                                    hintText: lang.translate('username'),
                                    icon: Icons.person_outline_rounded,
                                  ).animate(
                                    effects: [
                                      const FadeEffect(
                                        delay: Duration(milliseconds: 100),
                                        duration: Duration(milliseconds: 600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _emailController,
                                    hintText: lang.translate('email'),
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                  ).animate(
                                    effects: [
                                      const FadeEffect(
                                        delay: Duration(milliseconds: 200),
                                        duration: Duration(milliseconds: 600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hintText: lang.translate('password'),
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: !_isPasswordVisible,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                      ),
                                      onPressed: () => setState(() =>
                                          _isPasswordVisible =
                                              !_isPasswordVisible),
                                    ),
                                  ).animate(
                                    effects: [
                                      const FadeEffect(
                                        delay: Duration(milliseconds: 300),
                                        duration: Duration(milliseconds: 600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    hintText:
                                        lang.translate('confirm_password'),
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: !_isConfirmPasswordVisible,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                      ),
                                      onPressed: () => setState(() =>
                                          _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible),
                                    ),
                                  ).animate(
                                    effects: [
                                      const FadeEffect(
                                        delay: Duration(milliseconds: 400),
                                        duration: Duration(milliseconds: 600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildTermsCheckbox(lang),
                                  const SizedBox(height: 32),
                                  _buildRegisterButton(
                                    onPressed:
                                        _isLoading ? null : _handleRegister,
                                    isLoading: _isLoading,
                                    label: lang.translate('register'),
                                  ).animate(
                                    effects: [
                                      const FadeEffect(
                                        delay: Duration(milliseconds: 500),
                                        duration: Duration(milliseconds: 600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  _buildLoginLink(lang).animate(
                                    effects: [
                                      const FadeEffect(
                                        delay: Duration(milliseconds: 600),
                                        duration: Duration(milliseconds: 600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    ).animate(
      effects: [
        ShimmerEffect(
          duration: const Duration(seconds: 3),
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(LanguageProvider lang) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Transform.scale(
            scale: 0.8,
            child: Checkbox(
              value: _acceptTerms,
              onChanged: (value) =>
                  setState(() => _acceptTerms = value ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.5),
              ),
              checkColor: Colors.black,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return Colors.transparent;
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: lang.translate('accept_terms_prefix'),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              children: [
                TextSpan(
                  text: lang.translate('terms_and_conditions'),
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate(
      effects: [
        const FadeEffect(
          delay: Duration(milliseconds: 450),
          duration: Duration(milliseconds: 600),
        ),
      ],
    );
  }

  Widget _buildRegisterButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C4DFF), // Royal Purple
            Color(0xFF448AFF), // Bright Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    ).animate(
      effects: [
        ShimmerEffect(
          duration: const Duration(seconds: 2),
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  Widget _buildLoginLink(LanguageProvider lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          lang.translate('already_have_account'),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          child: Text(
            lang.translate('login'),
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
