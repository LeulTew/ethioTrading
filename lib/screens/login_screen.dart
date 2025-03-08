import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  final List<Color> _gradientColors = [
    const Color(0xFF1A237E), // Deep Ethiopian Blue
    const Color(0xFF8B0000), // Traditional Ethiopian Red
    const Color(0xFF006400), // Ethiopian Green
    const Color(0xFFFFD700), // Ethiopian Gold
  ];

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
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
    _passwordController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!context.mounted) return;
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
    // Enhanced particle with Ethiopian-inspired shapes
    return Positioned(
      left: x,
      top: y,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base particle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(size),
            ),
          ),
          // Ethiopian cross overlay (subtle)
          Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(size * 0.2),
            ),
          ),
        ],
      )
          .animate(
            onPlay: (controller) => controller.repeat(),
          )
          .moveY(
            duration: Duration(seconds: 2 + (x * 0.1).round()),
            begin: y - 20,
            end: y + 20,
            curve: Curves.easeInOut,
          )
          .rotate(
            duration: const Duration(seconds: 8),
            begin: 0,
            end: 0.1,
            curve: Curves.easeInOut,
          )
          .fadeIn(duration: const Duration(milliseconds: 500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Enhanced animated gradient background with Ethiopian colors
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Base gradient
                  Container(
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
                  ),
                  // Ethiopian flag-inspired subtle overlay
                  Opacity(
                    opacity: 0.03,
                    child: CustomPaint(
                      painter: EthiopianFlagPatternPainter(),
                      size: size,
                    ),
                  ),
                ],
              );
            },
          ),

          // Enhanced floating particles with more variety
          ...[
            _buildFloatingParticle(size.width * 0.2, size.height * 0.3, 6),
            _buildFloatingParticle(size.width * 0.8, size.height * 0.2, 8),
            _buildFloatingParticle(size.width * 0.5, size.height * 0.6, 5),
            _buildFloatingParticle(size.width * 0.15, size.height * 0.7, 7),
            _buildFloatingParticle(size.width * 0.85, size.height * 0.8, 6),
            _buildFloatingParticle(size.width * 0.4, size.height * 0.4, 4),
            _buildFloatingParticle(size.width * 0.7, size.height * 0.5, 5),
          ],

          // Main content with enhanced glass effect
          SingleChildScrollView(
            child: SizedBox(
              height: size.height,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Logo and Welcome Text
                      FadeInDown(
                        duration: const Duration(milliseconds: 1000),
                        child: Column(
                          children: [
                            // Modern app logo
                            _buildAppLogo(),
                            const SizedBox(height: 24),
                            Text(
                              lang.translate('welcome_back'),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            )
                                .animate()
                                .fadeIn(
                                  duration: const Duration(milliseconds: 800),
                                )
                                .slideY(
                                  begin: 0.3,
                                  curve: Curves.easeOutQuart,
                                ),
                            const SizedBox(height: 8),
                            Text(
                              lang.translate('login_subtitle'),
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

                      // Login Form
                      Expanded(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 1000),
                          delay: const Duration(milliseconds: 300),
                          child: _buildGlassContainer(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildTextField(
                                    controller: _emailController,
                                    hintText: lang.translate('email'),
                                    icon: Icons.email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: EmailValidator.validate,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hintText: lang.translate('password'),
                                    icon: Icons.lock_rounded,
                                    obscureText: !_isPasswordVisible,
                                    validator: PasswordValidator.validate,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_rounded
                                            : Icons.visibility_off_rounded,
                                        color: Colors.white
                                            .withAlpha(179), // 0.7 * 255
                                      ),
                                      onPressed: () => setState(() =>
                                          _isPasswordVisible =
                                              !_isPasswordVisible),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: Transform.scale(
                                              scale: 0.8,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) => setState(
                                                    () => _rememberMe =
                                                        value ?? false),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                side: BorderSide(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.5),
                                                ),
                                                checkColor: Colors.black,
                                                fillColor: WidgetStateProperty
                                                    .resolveWith((states) {
                                                  if (states.contains(
                                                      WidgetState.selected)) {
                                                    return Colors.white;
                                                  }
                                                  return Colors.transparent;
                                                }),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            lang.translate('remember_me'),
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pushNamed(
                                            context, '/forgot-password'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white
                                              .withValues(alpha: 0.7),
                                        ),
                                        child: Text(
                                          lang.translate('forgot_password'),
                                          style: GoogleFonts.spaceGrotesk(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  _buildLoginButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _handleLogin(context),
                                    isLoading: _isLoading,
                                    label: lang.translate('login'),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        lang.translate('new_user_prompt'),
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white
                                              .withAlpha(179), // 0.7 * 255
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pushNamed(
                                            context, '/register'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          lang.translate('register'),
                                          style: GoogleFonts.spaceGrotesk(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }

  // Enhanced glassmorphism container
  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // Enhanced modern app logo
  Widget _buildAppLogo() {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ethiopian pattern background (subtle)
          CustomPaint(
            painter: EthiopianPatternPainter(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            size: const Size(80, 80),
          ),
          // Modern icon
          const Icon(
            Icons.trending_up_rounded,
            size: 50,
            color: Colors.white,
          ),
          // Animated ring
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .rotate(
                duration: const Duration(seconds: 8),
                curve: Curves.easeInOut,
              ),
        ],
      ),
    ).animate(
      effects: [
        ShimmerEffect(
          duration: const Duration(seconds: 3),
          color: Colors.white.withValues(alpha: 0.2),
        ),
        const MoveEffect(
          begin: Offset(0, 10),
          end: Offset(0, 0),
          curve: Curves.easeOutQuart,
          duration: Duration(seconds: 1),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.5,
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
        validator: validator,
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

  Widget _buildLoginButton({
    required VoidCallback? onPressed,
    required bool isLoading,
    required String label,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFBB034), // Warm Gold
            Color(0xFFFF9D00), // Deep Amber
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBB034).withValues(alpha: 0.3),
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
}

class ModernEthiopianPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  ModernEthiopianPatternPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 60.0;
    const symbolSize = 20.0;

    for (var x = 0.0; x < size.width + symbolSize; x += spacing) {
      for (var y = 0.0; y < size.height + symbolSize; y += spacing) {
        // Draw modern interpretation of Ethiopian cross
        paint.color = primaryColor;
        final path = Path()
          ..moveTo(x - symbolSize / 2, y)
          ..lineTo(x + symbolSize / 2, y)
          ..moveTo(x, y - symbolSize / 2)
          ..lineTo(x, y + symbolSize / 2);

        canvas.drawPath(path, paint);

        // Draw circular element
        paint.color = secondaryColor;
        canvas.drawCircle(Offset(x, y), symbolSize / 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(ModernEthiopianPatternPainter oldDelegate) => false;
}

// Ethiopian Pattern Painter
class EthiopianPatternPainter extends CustomPainter {
  final Color color;

  EthiopianPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const spacing = 10.0;
    const symbolSize = 4.0;

    for (var i = 0.0; i < size.width; i += spacing) {
      for (var j = 0.0; j < size.height; j += spacing) {
        // Draw Ethiopian cross pattern
        canvas.drawLine(
          Offset(i, j),
          Offset(i + symbolSize, j + symbolSize),
          paint,
        );
        canvas.drawLine(
          Offset(i + symbolSize, j),
          Offset(i, j + symbolSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(EthiopianPatternPainter oldDelegate) => false;
}

// Add new Ethiopian flag pattern painter
class EthiopianFlagPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const colors = [
      Color(0xFF009A44), // Green
      Color(0xFFFFCD00), // Yellow
      Color(0xFFEE1C25), // Red
    ];

    final stripHeight = size.height / 3;

    for (var i = 0; i < colors.length; i++) {
      paint.color = colors[i];

      final y = stripHeight * i;
      final path = Path();

      // Create subtle wave pattern in each stripe
      for (var x = 0.0; x < size.width; x += 50.0) {
        if (path.getBounds().width == 0) {
          path.moveTo(x, y + (sin(x / 30.0) * 5.0));
        }
        path.lineTo(x + 25.0, y + stripHeight / 2 + (sin(x / 30.0) * 5.0));
        path.lineTo(x + 50.0, y + stripHeight + (sin(x / 30.0) * 5.0));
      }

      canvas.drawPath(path, paint);
    }

    // Add subtle star pattern
    paint.color = const Color(0xFFFFCD00).withValues(alpha: 0.1);
    for (var i = 0.0; i < size.width; i += 100.0) {
      for (var j = 0.0; j < size.height; j += 100.0) {
        _drawStar(canvas, paint, Offset(i, j), 5.0);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final angle = (i * 4 * pi) / 5;
      final point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(EthiopianFlagPatternPainter oldDelegate) => false;
}
