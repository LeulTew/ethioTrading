import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'wave_clipper.dart';
import 'dart:async';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _waveProgressAnimation;
  late Timer _waveAnimationTimer;
  double _wavePhase = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Animation for smooth movement between tabs
    _waveProgressAnimation = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));

    // Timer for continuous subtle wave animation
    _waveAnimationTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _wavePhase += 0.05;
        if (_wavePhase > 2 * math.pi) {
          _wavePhase -= 2 * math.pi;
        }
      });
    });
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      // Animate the wave to the new position
      _waveProgressAnimation = Tween<double>(
        begin: _waveProgressAnimation.value,
        end: widget.currentIndex.toDouble(),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ));
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _waveAnimationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final mediaQuery = MediaQuery.of(context);

    // Define navigation items
    final List<Map<String, dynamic>> navItems = [
      {
        'icon': Icons.home_rounded,
        'label': languageProvider.translate('home'),
      },
      {
        'icon': Icons.show_chart_rounded,
        'label': languageProvider.translate('market'),
      },
      {
        'icon': Icons.account_balance_wallet_rounded,
        'label': languageProvider.translate('portfolio'),
      },
      {
        'icon': Icons.person_rounded,
        'label': languageProvider.translate('profile'),
      },
    ];

    // Calculate safe height to avoid overflow
    const safeHeight = 68.0; // Slightly reduced from 70.0
    final bottomPadding = mediaQuery.padding.bottom;
    final totalHeight = safeHeight + bottomPadding;

    return AnimatedBuilder(
      animation: _waveProgressAnimation,
      builder: (context, _) {
        return Container(
          height: totalHeight,
          decoration: BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Base background layer with transparent base - goes all the way to the bottom
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    // Slightly purplish transparent background
                    color: theme.colorScheme.primary.withValues(alpha: 0.04),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),

              // Wave effects positioned at the TOP
              // First wave - base effect with purplish tint
              Positioned(
                left: 0,
                right: 0,
                top: -2, // Slightly above to ensure wave blends with edge
                bottom: 0, // Extend to bottom
                child: ClipPath(
                  clipper: WaveClipper(
                    waveHeight: 26.0, // Slightly reduced height
                    waveWidth: mediaQuery.size.width / 4 * 1.2,
                    progress: _waveProgressAnimation.value,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          // More purplish tint in the gradient
                          theme.colorScheme.primary.withValues(alpha: 0.12),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Second wave with breathing effect - also with purplish tint
              Positioned(
                left: 0,
                right: 0,
                top: -2, // Slightly above to ensure wave blends with edge
                bottom: 0, // Extend to bottom
                child: ClipPath(
                  clipper: WaveClipper(
                    waveHeight: 26.0 + 2.0 * math.sin(_wavePhase),
                    waveWidth: mediaQuery.size.width / 4 * 1.2,
                    progress: _waveProgressAnimation.value,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          // More purplish gradient colors
                          AppTheme.primaryGradient.first
                              .withValues(alpha: 0.15),
                          AppTheme.primaryGradient.last.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Navigation items after wave effects (so they're clickable on top)
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomPadding,
                top: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    navItems.length,
                    (index) => _buildNavItem(
                      context,
                      navItems[index]['icon'],
                      navItems[index]['label'],
                      index,
                      theme,
                      mediaQuery,
                    ),
                  ),
                ),
              ),

              // Selected item indicator dot
              AnimatedPositioned(
                duration: Duration.zero, // Handled by AnimatedBuilder instead
                curve: Curves.easeOutCubic,
                bottom: bottomPadding + 9, // Adjusted position
                left: (mediaQuery.size.width / navItems.length) *
                        _waveProgressAnimation.value +
                    (mediaQuery.size.width / navItems.length) * 0.5 -
                    4,
                child: Container(
                  width: 6, // Smaller dot
                  height: 6, // Smaller dot
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGradient.last
                            .withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    ThemeData theme,
    MediaQueryData mediaQuery,
  ) {
    final isSelected = widget.currentIndex == index;
    final itemWidth = mediaQuery.size.width / 4;

    // Dynamic icon size - smaller for non-selected, larger for selected
    final iconSize = isSelected ? 22.0 : 18.0;

    return InkWell(
      onTap: () => widget.onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add extra top space to move icons down slightly
            const SizedBox(height: 4),

            // Icon with animated container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.all(isSelected ? 8 : 7),
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppTheme.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : null,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: iconSize, // Dynamic size based on selection state
                ),
              ),
            ),

            const SizedBox(height: 3), // Smaller gap

            // Label with enhanced contrast but smaller size
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 10, // Even smaller font size to prevent overflow
                letterSpacing: 0.1,
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
