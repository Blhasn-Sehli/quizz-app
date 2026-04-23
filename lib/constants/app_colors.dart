import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LEGACY BRIDGE — AppColors static constants
///
/// These are kept for backward compatibility with screens that import AppColors
/// directly. New code should use `context.tokens` from app_theme.dart instead.
///
/// NOTE: Static constants here reflect the DARK theme palette.
/// For runtime theme-aware colors, use: Theme.of(context).extension<AppColorTokens>()
/// or the shorthand: context.tokens
/// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Background & Surface (dark defaults)
  static const bg           = Color(0xFF091614);
  static const bgDeep       = Color(0xFF040D0C);
  static const surface      = Color(0xFF0F2320);
  static const surfaceHigh  = Color(0xFF163330);
  static const border       = Color(0xFF1E4440);

  // Primary — Deep Teal
  static const primary      = Color(0xFF3DA899);
  static const primaryLight = Color(0xFF5EC5B5);
  static const primarySoft  = Color(0xFF226660);

  // Accent — Warm Amber
  static const accent       = Color(0xFFF59E0B);
  static const accentLight  = Color(0xFFFBBF24);
  static const accentSoft   = Color(0xFF3D2800);

  // Semantic
  static const success      = Color(0xFF10B981);
  static const danger       = Color(0xFFF87171);
  static const warning      = Color(0xFFF59E0B);

  // Text
  static const text         = Color(0xFFE8F5F3);
  static const textMuted    = Color(0xFF4A7A75);
  static const textSub      = Color(0xFF8CBDB8);
  static const white        = Colors.white;

  // ── GRADIENTS ──────────────────────────────────────────────────────────
  /// Primary action gradient — teal
  static const gradBtn = LinearGradient(
    colors: [Color(0xFF226660), Color(0xFF3DA899)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Success / join action — teal-to-emerald
  static const gradBtnGreen = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Card surface gradient
  static const gradCard = LinearGradient(
    colors: [Color(0xFF0F2320), Color(0xFF132B27)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// PIN display gradient — teal + amber
  static const gradPin = LinearGradient(
    colors: [Color(0xFF226660), Color(0xFF3DA899), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Amber accent gradient
  static const gradAccent = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
