import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  final List<Color> _gradientColors = [
    const Color(0xFF6A1B9A), // Deep Purple
    const Color(0xFF4527A0), // Deep Indigo
    const Color(0xFF283593), // Royal Blue
    const Color(0xFF1565C0), // Ocean Blue
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
    _emailController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.resetPassword(_emailController.text.trim());

      if (!mounted) return;
      setState(() => _emailSent = true);
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
      ).animate(
        effects: [
          MoveEffect(
            duration: Duration(seconds: 3 + (x * 0.1).round()),
            begin: Offset(0, y - 30),
            end: Offset(0, y + 30),
            curve: Curves.easeInOut,
          ),
          const FadeEffect(duration: Duration(milliseconds: 600)),
        ],
        onPlay: (controller) => controller.repeat(reverse: true),
      ),
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
            _buildFloatingParticle(size.width * 0.2, size.height * 0.2, 4),
            _buildFloatingParticle(size.width * 0.8, size.height * 0.3, 6),
            _buildFloatingParticle(size.width * 0.5, size.height * 0.5, 3),
            _buildFloatingParticle(size.width * .15, size.height * 0.7, 5),
            _buildFloatingParticle(size.width * 0.9, size.height * 0.8, 4),
          ],

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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

                  const SizedBox(height: 40),

                  if (!_emailSent) ...[
                    _buildResetPasswordForm(lang),
                  ] else ...[
                    _buildSuccessMessage(lang),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordForm(LanguageProvider lang) {
    return Column(
      children: [
        // Header Section
        FadeInDown(
          duration: const Duration(milliseconds: 800),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 48,
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
              const SizedBox(height: 32),
              Text(
                lang.translate('forgot_password'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ).animate(
                effects: [
                  const FadeEffect(duration: Duration(milliseconds: 800)),
                  const SlideEffect(
                    begin: Offset(0, 0.3),
                    curve: Curves.easeOutQuart,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                lang.translate('reset_password_subtitle'),
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

        const SizedBox(height: 48),

        // Reset Form
        FadeInUp(
          duration: const Duration(milliseconds: 800),
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
                      const SizedBox(height: 32),
                      _buildResetButton(
                        onPressed: _isLoading ? null : _handleResetPassword,
                        isLoading: _isLoading,
                        label: lang.translate('send_reset_link'),
                      ).animate(
                        effects: [
                          const FadeEffect(
                            delay: Duration(milliseconds: 400),
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
      ],
    );
  }

  Widget _buildSuccessMessage(LanguageProvider lang) {
    return FadeInDown(
      duration: const Duration(milliseconds: 800),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 64,
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
          const SizedBox(height: 32),
          Text(
            lang.translate('reset_link_sent'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            lang.translate('check_email_instructions'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildReturnToLoginButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            label: lang.translate('back_to_login'),
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

  Widget _buildResetButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6200EA), // Deep Purple
            Color(0xFF304FFE), // Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6200EA).withValues(alpha: 0.3),
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

  Widget _buildReturnToLoginButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded, size: 20),
        label: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
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
}
