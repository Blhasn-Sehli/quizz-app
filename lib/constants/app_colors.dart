import 'package:flutter/material.dart';

/// Centralized color palette for the Quiz App
/// Uses consistent design tokens across all screens
class AppColors {
  // Background & Surface
  static const bg           = Color(0xFF0D1B2A);
  static const surface      = Color(0xFF162032);
  static const surfaceHigh  = Color(0xFF1E2D42);
  static const border       = Color(0xFF2A3F5F);

  // Primary Colors
  static const primary      = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primarySoft  = Color(0xFF4F46E5);

  // Accent Colors
  static const accent       = Color(0xFF7C3AED);
  static const accentLight  = Color(0xFFA78BFA);

  // Semantic Colors
  static const success      = Color(0xFF10B981);
  static const danger       = Color(0xFFEF4444);
  static const warning      = Color(0xFFF59E0B);

  // Text Colors
  static const text         = Color(0xFFE2E8F0);
  static const textMuted    = Color(0xFF64748B);
  static const textSub      = Color(0xFF94A3B8);
  static const white        = Colors.white;

  // Gradients
  static const gradBtn = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradBtnGreen = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const gradCard = LinearGradient(
    colors: [Color(0xFF162032), Color(0xFF1A2640)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradPin = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
