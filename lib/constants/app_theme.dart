import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// DESIGN IDENTITY: Deep Teal + Warm Amber (editorial / premium)
///
/// Dark  → Ocean-slate backgrounds, amber-gold accents, cream text
/// Light → Warm cream/ivory backgrounds, deep teal primary, amber highlights
///
/// Token system mirrors CSS custom properties so the entire palette
/// switches as one coherent unit — never just color-inverted.
/// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ── RAW PALETTE ──────────────────────────────────────────────────────────
  // Teal family
  static const _teal900 = Color(0xFF0D2B2B);
  static const _teal800 = Color(0xFF133A38);
  static const _teal700 = Color(0xFF1A4D49);
  static const _teal600 = Color(0xFF226660);
  static const _teal500 = Color(0xFF2A8077);
  static const _teal400 = Color(0xFF3DA899);
  static const _teal300 = Color(0xFF5EC5B5);
  static const _teal200 = Color(0xFF8ED8CC);
  static const _teal100 = Color(0xFFBFEDE7);

  // Amber family
  static const _amber700 = Color(0xFF92400E);
  static const _amber500 = Color(0xFFD97706);
  static const _amber400 = Color(0xFFF59E0B);
  static const _amber300 = Color(0xFFFBBF24);
  static const _amber100 = Color(0xFFFEF3C7);

  // Neutrals
  static const _slate950 = Color(0xFF040D0C);
  static const _slate900 = Color(0xFF091614);
  static const _slate800 = Color(0xFF0F2320);
  static const _slate700 = Color(0xFF163330);
  static const _slate600 = Color(0xFF1E4440);
  static const _cream50  = Color(0xFFFAF7F2);
  static const _cream100 = Color(0xFFF5F0E8);
  static const _cream200 = Color(0xFFEDE5D5);
  static const _cream300 = Color(0xFFD6C9B4);

  // Semantic
  static const _emerald500 = Color(0xFF10B981);
  static const _rose500    = Color(0xFFEF4444);
  static const _rose400    = Color(0xFFF87171);

  // ── EXTENSION COLORS (accessed via Theme.of(context).extension) ──────────
  static const _darkTokens = AppColorTokens(
    bg:          _slate900,
    bgDeep:      _slate950,
    surface:     _slate800,
    surfaceHigh: _slate700,
    surfacePop:  _slate600,
    border:      Color(0xFF1E4440),
    borderSoft:  Color(0xFF153330),
    primary:     _teal400,
    primaryDim:  _teal500,
    primaryGlow: _teal300,
    accent:      _amber400,
    accentDim:   _amber500,
    accentSoft:  Color(0xFF3D2800),
    text:        Color(0xFFE8F5F3),
    textSub:     Color(0xFF8CBDB8),
    textMuted:   Color(0xFF4A7A75),
    success:     _emerald500,
    danger:      _rose400,
    warning:     _amber400,
    isDark:      true,
  );

  static const _lightTokens = AppColorTokens(
    bg:          _cream50,
    bgDeep:      _cream100,
    surface:     Colors.white,
    surfaceHigh: _cream100,
    surfacePop:  _cream200,
    border:      Color(0xFFD6C9B4),
    borderSoft:  Color(0xFFEDE5D5),
    primary:     _teal600,
    primaryDim:  _teal700,
    primaryGlow: _teal400,
    accent:      _amber500,
    accentDim:   _amber700,
    accentSoft:  Color(0xFFFEF3C7),
    text:        Color(0xFF0D2B2B),
    textSub:     Color(0xFF2A6660),
    textMuted:   Color(0xFF5A8A84),
    success:     Color(0xFF059669),
    danger:      _rose500,
    warning:     _amber500,
    isDark:      false,
  );

  // ── TEXT THEME ────────────────────────────────────────────────────────────
  // Syne for display / headings (bold, editorial character)
  // Plus Jakarta Sans for body (clean, modern, readable)
  static TextTheme _textTheme(Color text, Color sub) => TextTheme(
        displayLarge: GoogleFonts.syne(
            color: text, fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -1.5, height: 1.05),
        displayMedium: GoogleFonts.syne(
            color: text, fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.1),
        displaySmall: GoogleFonts.syne(
            color: text, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.15),
        headlineLarge: GoogleFonts.syne(
            color: text, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.4),
        headlineMedium: GoogleFonts.syne(
            color: text, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineSmall: GoogleFonts.syne(
            color: text, fontSize: 18, fontWeight: FontWeight.w700),
        titleLarge: GoogleFonts.plusJakartaSans(
            color: text, fontSize: 16, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.plusJakartaSans(
            color: text, fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.plusJakartaSans(
            color: sub, fontSize: 12, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.plusJakartaSans(
            color: text, fontSize: 15, fontWeight: FontWeight.w400, height: 1.6),
        bodyMedium: GoogleFonts.plusJakartaSans(
            color: text, fontSize: 14, fontWeight: FontWeight.w400, height: 1.55),
        bodySmall: GoogleFonts.plusJakartaSans(
            color: sub, fontSize: 12, fontWeight: FontWeight.w400, height: 1.5),
        labelLarge: GoogleFonts.plusJakartaSans(
            color: text, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
        labelMedium: GoogleFonts.plusJakartaSans(
            color: sub, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        labelSmall: GoogleFonts.plusJakartaSans(
            color: sub, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0),
      );

  // ── DARK THEME ────────────────────────────────────────────────────────────
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    extensions: const [_darkTokens],
    scaffoldBackgroundColor: _slate900,
    colorScheme: ColorScheme.dark(
      primary:       _teal400,
      secondary:     _amber400,
      surface:       _slate800,
      error:         _rose400,
      onPrimary:     _slate900,
      onSecondary:   _slate900,
      onSurface:     const Color(0xFFE8F5F3),
      outline:       const Color(0xFF1E4440),
    ),
    textTheme: _textTheme(const Color(0xFFE8F5F3), const Color(0xFF8CBDB8)),
    cardTheme: CardThemeData(
      color: _slate800,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF1E4440), width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF1E4440), space: 0),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: _teal400),
  );

  // ── LIGHT THEME ───────────────────────────────────────────────────────────
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: const [_lightTokens],
    scaffoldBackgroundColor: _cream50,
    colorScheme: ColorScheme.light(
      primary:       _teal600,
      secondary:     _amber500,
      surface:       Colors.white,
      error:         _rose500,
      onPrimary:     Colors.white,
      onSecondary:   Colors.white,
      onSurface:     const Color(0xFF0D2B2B),
      outline:       const Color(0xFFD6C9B4),
    ),
    textTheme: _textTheme(const Color(0xFF0D2B2B), const Color(0xFF2A6660)),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD6C9B4), width: 1),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFD6C9B4), space: 0),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: _teal600),
  );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// DESIGN TOKEN EXTENSION
/// Access anywhere via: Theme.of(context).tokens
/// ─────────────────────────────────────────────────────────────────────────────
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color bg;
  final Color bgDeep;
  final Color surface;
  final Color surfaceHigh;
  final Color surfacePop;
  final Color border;
  final Color borderSoft;
  final Color primary;
  final Color primaryDim;
  final Color primaryGlow;
  final Color accent;
  final Color accentDim;
  final Color accentSoft;
  final Color text;
  final Color textSub;
  final Color textMuted;
  final Color success;
  final Color danger;
  final Color warning;
  final bool isDark;

  const AppColorTokens({
    required this.bg,
    required this.bgDeep,
    required this.surface,
    required this.surfaceHigh,
    required this.surfacePop,
    required this.border,
    required this.borderSoft,
    required this.primary,
    required this.primaryDim,
    required this.primaryGlow,
    required this.accent,
    required this.accentDim,
    required this.accentSoft,
    required this.text,
    required this.textSub,
    required this.textMuted,
    required this.success,
    required this.danger,
    required this.warning,
    required this.isDark,
  });

  @override
  AppColorTokens copyWith({
    Color? bg, Color? bgDeep, Color? surface, Color? surfaceHigh,
    Color? surfacePop, Color? border, Color? borderSoft,
    Color? primary, Color? primaryDim, Color? primaryGlow,
    Color? accent, Color? accentDim, Color? accentSoft,
    Color? text, Color? textSub, Color? textMuted,
    Color? success, Color? danger, Color? warning, bool? isDark,
  }) => AppColorTokens(
    bg:          bg          ?? this.bg,
    bgDeep:      bgDeep      ?? this.bgDeep,
    surface:     surface     ?? this.surface,
    surfaceHigh: surfaceHigh ?? this.surfaceHigh,
    surfacePop:  surfacePop  ?? this.surfacePop,
    border:      border      ?? this.border,
    borderSoft:  borderSoft  ?? this.borderSoft,
    primary:     primary     ?? this.primary,
    primaryDim:  primaryDim  ?? this.primaryDim,
    primaryGlow: primaryGlow ?? this.primaryGlow,
    accent:      accent      ?? this.accent,
    accentDim:   accentDim   ?? this.accentDim,
    accentSoft:  accentSoft  ?? this.accentSoft,
    text:        text        ?? this.text,
    textSub:     textSub     ?? this.textSub,
    textMuted:   textMuted   ?? this.textMuted,
    success:     success     ?? this.success,
    danger:      danger      ?? this.danger,
    warning:     warning     ?? this.warning,
    isDark:      isDark      ?? this.isDark,
  );

  @override
  AppColorTokens lerp(AppColorTokens? other, double t) {
    if (other == null) return this;
    return AppColorTokens(
      bg:          Color.lerp(bg,          other.bg,          t)!,
      bgDeep:      Color.lerp(bgDeep,      other.bgDeep,      t)!,
      surface:     Color.lerp(surface,     other.surface,     t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      surfacePop:  Color.lerp(surfacePop,  other.surfacePop,  t)!,
      border:      Color.lerp(border,      other.border,      t)!,
      borderSoft:  Color.lerp(borderSoft,  other.borderSoft,  t)!,
      primary:     Color.lerp(primary,     other.primary,     t)!,
      primaryDim:  Color.lerp(primaryDim,  other.primaryDim,  t)!,
      primaryGlow: Color.lerp(primaryGlow, other.primaryGlow, t)!,
      accent:      Color.lerp(accent,      other.accent,      t)!,
      accentDim:   Color.lerp(accentDim,   other.accentDim,   t)!,
      accentSoft:  Color.lerp(accentSoft,  other.accentSoft,  t)!,
      text:        Color.lerp(text,        other.text,        t)!,
      textSub:     Color.lerp(textSub,     other.textSub,     t)!,
      textMuted:   Color.lerp(textMuted,   other.textMuted,   t)!,
      success:     Color.lerp(success,     other.success,     t)!,
      danger:      Color.lerp(danger,      other.danger,      t)!,
      warning:     Color.lerp(warning,     other.warning,     t)!,
      isDark:      isDark,
    );
  }
}

/// Quick accessor extension — so any widget can write `context.tokens`
extension AppThemeContext on BuildContext {
  AppColorTokens get tokens =>
      Theme.of(this).extension<AppColorTokens>()!;
}
