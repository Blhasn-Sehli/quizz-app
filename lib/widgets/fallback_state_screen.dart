import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';
import '../constants/app_colors.dart';

class FallbackStateScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final String? primaryRoute;
  final String secondaryLabel;
  final String secondaryRoute;
  final bool isLoading;

  const FallbackStateScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.primaryLabel = 'Go Back',
    this.primaryRoute,
    this.secondaryLabel = 'Go Home',
    this.secondaryRoute = AppRoutes.home,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: AppColors.gradCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.gradBtn,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: Icon(icon, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    if (isLoading) ...[
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ],
                    if (!isLoading) ...[
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: primaryLabel,
                              icon: Icons.arrow_back_rounded,
                              filled: false,
                              onTap: () {
                                final route = primaryRoute;
                                if (route == null) {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go(AppRoutes.home);
                                  }
                                  return;
                                }
                                context.go(route);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: secondaryLabel,
                              icon: Icons.home_rounded,
                              filled: true,
                              onTap: () => context.go(secondaryRoute),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? null : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: filled ? AppColors.gradBtn : null,
            color: filled ? null : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: filled ? Colors.transparent : AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: filled ? Colors.white : AppColors.text, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: filled ? Colors.white : AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
