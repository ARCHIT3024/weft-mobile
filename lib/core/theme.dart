/// Weft design tokens — matching DECISIONS.md and 03_weft_uiux.jsx.
///
/// ACCESSIBILITY (WCAG 2.1 AA): brand teal `#0EA5A0` is only 3.0:1 against
/// white — fine for large graphics (FAB, icons ≥ 3:1) but NOT for text or
/// text-bearing buttons (need 4.5:1). Text-bearing surfaces therefore use
/// [WeftColors.tealAccessible] (`#0B7A76`, 5.2:1 on white). The brand teal is
/// kept for decoration, the FAB and selected-state accents.
library;

import 'package:flutter/material.dart';

class WeftColors {
  WeftColors._();

  // ── Brand ────────────────────────────────────────────────────────
  static const Color navy = Color(0xFF0F2A4A);
  static const Color navyLight = Color(0xFF1A3D6B);
  static const Color navyDark = Color(0xFF0A1E36);

  static const Color teal = Color(0xFF0EA5A0);
  static const Color tealLight = Color(0xFF14D4CC);
  static const Color tealDark = Color(0xFF0B8480);

  /// Teal that passes AA for normal text on white/surface (5.2:1) and for
  /// white text on it. Use for buttons, links, focused borders.
  static const Color tealAccessible = Color(0xFF0B7A76);

  /// Tinted background for selected chips/cards (`tealBg` in the UI spec).
  static const Color tealBackground = Color(0xFFE0F7F6);

  static const Color orange = Color(0xFFF59E0B);
  static const Color orangeLight = Color(0xFFFBBF24);
  static const Color orangeDark = Color(0xFFD97706);

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFF87171);

  /// Error text on light backgrounds (4.8:1 on white).
  static const Color dangerText = Color(0xFFDC2626);

  // ── Neutral ──────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);

  /// 4.6:1 on surface — the lightest grey allowed for body text.
  static const Color textSecondary = Color(0xFF64748B);

  /// 2.6:1 — decorative/disabled only, never for meaningful text.
  static const Color textMuted = Color(0xFF94A3B8);
}

/// Spacing/radius scale used across screens.
class WeftSpacing {
  WeftSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Screen edge padding.
  static const double screen = 16;
  static const double radius = 12;
  static const double radiusLarge = 16;

  /// WCAG 2.5.5 / Material: minimum interactive size.
  static const double minTouchTarget = 48;

  /// Bottom padding for scrollables in the home shell so the last item is not
  /// hidden behind the centred "Report Issue" FAB.
  static const double fabClearance = 96;
}

class WeftTheme {
  WeftTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: WeftColors.teal,
      primary: WeftColors.tealAccessible,
      onPrimary: Colors.white,
      primaryContainer: WeftColors.tealBackground,
      onPrimaryContainer: WeftColors.navy,
      secondary: WeftColors.navy,
      onSecondary: Colors.white,
      surface: WeftColors.surface,
      onSurface: WeftColors.textPrimary,
      onSurfaceVariant: WeftColors.textSecondary,
      error: WeftColors.dangerText,
      outline: WeftColors.border,
    );
    const minButtonSize = Size(64, 52);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(WeftSpacing.radius),
    );
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: WeftColors.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: WeftColors.navy,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: WeftColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: WeftColors.tealAccessible,
        foregroundColor: Colors.white,
        extendedTextStyle: buttonText,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WeftColors.tealAccessible,
          foregroundColor: Colors.white,
          minimumSize: minButtonSize,
          shape: buttonShape,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: WeftColors.tealAccessible,
          foregroundColor: Colors.white,
          minimumSize: minButtonSize,
          shape: buttonShape,
          textStyle: buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WeftColors.tealAccessible,
          minimumSize: minButtonSize,
          shape: buttonShape,
          textStyle: buttonText,
          side: const BorderSide(color: WeftColors.tealAccessible, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WeftColors.tealAccessible,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: WeftColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: WeftColors.tealAccessible),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeftSpacing.radius),
          borderSide: const BorderSide(color: WeftColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeftSpacing.radius),
          borderSide: const BorderSide(color: WeftColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeftSpacing.radius),
          borderSide: const BorderSide(
            color: WeftColors.tealAccessible,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeftSpacing.radius),
          borderSide: const BorderSide(color: WeftColors.dangerText),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WeftSpacing.radius),
          borderSide: const BorderSide(color: WeftColors.dangerText, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WeftSpacing.radiusLarge),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: WeftColors.tealBackground,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? WeftColors.tealAccessible
                : WeftColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? WeftColors.tealAccessible
                : WeftColors.textSecondary,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: WeftColors.navy,
      ),
    );
  }
}
