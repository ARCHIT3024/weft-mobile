/// Weft design tokens — matching DECISIONS.md
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

  static const Color orange = Color(0xFFF59E0B);
  static const Color orangeLight = Color(0xFFFBBF24);
  static const Color orangeDark = Color(0xFFD97706);

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFF87171);

  // ── Neutral ──────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
}

class WeftTheme {
  WeftTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: WeftColors.teal,
          primary: WeftColors.teal,
          onPrimary: Colors.white,
          secondary: WeftColors.navy,
          onSecondary: Colors.white,
          surface: WeftColors.surface,
          error: WeftColors.danger,
        ),
        scaffoldBackgroundColor: WeftColors.surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: WeftColors.navy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: WeftColors.teal,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: WeftColors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WeftColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WeftColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: WeftColors.teal, width: 2),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
