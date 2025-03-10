import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

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
    const safeHeight = 65.0;
    final bottomPadding = mediaQuery.padding.bottom;
    final totalHeight = safeHeight + bottomPadding;

    return Container(
      height: totalHeight,
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Stack(
          children: [
            // Background blur and gradient
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.surface.withValues(alpha: 0.92),
                        theme.colorScheme.surface.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Navigation items
            Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
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

            // Animated selection indicator - pill shape
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              bottom: bottomPadding + 8,
              left: (mediaQuery.size.width / navItems.length) * currentIndex +
                  (mediaQuery.size.width / navItems.length) * 0.25,
              child: Container(
                width: mediaQuery.size.width /
                    navItems.length *
                    0.5, // 50% of item width
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.primaryGradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGradient.last.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
    final isSelected = currentIndex == index;
    final itemWidth = mediaQuery.size.width / 4;

    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add extra top space to move icons down slightly
            const SizedBox(height: 2),

            // Icon with animated container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                size: 20, // Reduced size to prevent overflow
              ),
            ),

            const SizedBox(height: 2),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11, // Smaller text size
                letterSpacing: 0.1,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
