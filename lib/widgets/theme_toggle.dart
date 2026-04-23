import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_theme.dart';

/// Animated pill-style light/dark mode toggle.
/// Drop it anywhere — top-right of a nav bar, inside a Stack, etc.
///
/// Visual design:
///   Dark  → deep teal pill, amber sun icon slides to the right
///   Light → cream pill, teal moon icon slides to the left
///
/// Animation: 300 ms ease-in-out on all properties simultaneously.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final t = context.tokens;
    final isDark = provider.isDark;

    return GestureDetector(
      onTap: provider.toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 58,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isDark ? t.surfacePop : t.cream,
          border: Border.all(
            color: isDark ? t.primary.withOpacity(0.5) : t.primary.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: t.primary.withOpacity(isDark ? 0.25 : 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Track icons (always visible, dimmed)
            Positioned(
              left: 3,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isDark ? 1.0 : 0.25,
                  child: Icon(Icons.nights_stay_rounded, size: 13, color: t.accent),
                ),
              ),
            ),
            Positioned(
              right: 3,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isDark ? 0.25 : 1.0,
                  child: Icon(Icons.wb_sunny_rounded, size: 13, color: t.accent),
                ),
              ),
            ),
            // Sliding thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerLeft : Alignment.centerRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? t.primary : t.primary,
                  boxShadow: [
                    BoxShadow(
                      color: t.primary.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isDark
                        ? Icon(Icons.nights_stay_rounded,
                            key: const ValueKey('moon'),
                            size: 12,
                            color: Colors.white)
                        : Icon(Icons.wb_sunny_rounded,
                            key: const ValueKey('sun'),
                            size: 12,
                            color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper extension for the cream color in light mode
extension _TokenExt on AppColorTokens {
  Color get cream => isDark ? surfacePop : const Color(0xFFFAF7F2);
}
