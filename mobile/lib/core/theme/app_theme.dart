// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Semantic Color Helper ────────────────────────────────────────────────────
// Use AppColors.of(context) anywhere in the widget tree to get colors that
// automatically adapt to the active theme (dark or light).
class AppColors {
  AppColors._(this._t);
  final ThemeData _t;

  static AppColors of(BuildContext context) => AppColors._(Theme.of(context));

  Color get bg         => _t.scaffoldBackgroundColor;
  Color get card       => _t.colorScheme.surface;
  Color get cardLight  => _t.colorScheme.surfaceContainerHighest;
  Color get border     => _t.dividerColor;
  Color get text       => _t.colorScheme.onSurface;
  Color get textSub    => _t.colorScheme.onSurfaceVariant;
  Color get textMuted  => _t.colorScheme.outline;
  Color get primary    => _t.colorScheme.primary;
  Color get accent     => _t.colorScheme.secondary;
  Color get danger     => _t.colorScheme.error;

  // Semantic colours shared across both themes
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFFB347);
  static const Color info    = Color(0xFF4FC3F7);
}

// ─── AppTheme ─────────────────────────────────────────────────────────────────
class AppTheme {
  // ── Brand / Semantic (same in both themes) ────────────────────────────────
  static const Color primary     = Color(0xFF6C63FF);   // Electric violet
  static const Color primaryDark = Color(0xFF4A45B0);
  static const Color accent      = Color(0xFF00D4AA);   // Teal green
  static const Color warning     = Color(0xFFFFB347);   // Amber
  static const Color danger      = Color(0xFFFF6B6B);   // Coral red
  static const Color success     = Color(0xFF51CF66);   // Green

  // ── Dark palette ─────────────────────────────────────────────────────────
  static const Color bgDark      = Color(0xFF0D0D1A);
  static const Color bgCard      = Color(0xFF16162A);
  static const Color bgCardLight = Color(0xFF1E1E35);
  static const Color borderColor = Color(0xFF2A2A45);

  static const Color textPrimary   = Color(0xFFE8E8FF);
  static const Color textSecondary = Color(0xFF8888BB);
  static const Color textMuted     = Color(0xFF555577);

  // ── Light palette ─────────────────────────────────────────────────────────
  static const Color bgLight       = Color(0xFFF5F5FF);   // Soft lavender-white
  static const Color bgCardWhite   = Color(0xFFFFFFFF);
  static const Color bgCardWhiteEl = Color(0xFFF0F0FF);   // Slightly elevated
  static const Color borderLight   = Color(0xFFDDDDF0);

  static const Color textDark      = Color(0xFF1A1A2E);
  static const Color textDarkSub   = Color(0xFF5555AA);
  static const Color textDarkMuted = Color(0xFFAAAAAA);

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: bgCard,
        surfaceContainerHighest: bgCardLight,
        error: danger,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: textMuted,
        outlineVariant: borderColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge:   TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          displayMedium:  TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineLarge:  TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge:     TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium:    TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
          bodyLarge:      TextStyle(color: textPrimary),
          bodyMedium:     TextStyle(color: textSecondary),
          bodySmall:      TextStyle(color: textMuted),
          labelLarge:     TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Outfit',
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderColor, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgCard,
        indicatorColor: primary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? primary : textMuted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              color: s.contains(WidgetState.selected) ? primary : textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? accent : textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accent.withValues(alpha: 0.4)
                : borderColor),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCardLight,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgLight,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: bgCardWhite,
        surfaceContainerHighest: bgCardWhiteEl,
        error: danger,
        onSurface: textDark,
        onSurfaceVariant: textDarkSub,
        outline: textDarkMuted,
        outlineVariant: borderLight,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge:   TextStyle(color: textDark, fontWeight: FontWeight.bold),
          displayMedium:  TextStyle(color: textDark, fontWeight: FontWeight.bold),
          headlineLarge:  TextStyle(color: textDark, fontWeight: FontWeight.w600),
          headlineMedium: TextStyle(color: textDark, fontWeight: FontWeight.w600),
          titleLarge:     TextStyle(color: textDark, fontWeight: FontWeight.w600),
          titleMedium:    TextStyle(color: textDark, fontWeight: FontWeight.w500),
          bodyLarge:      TextStyle(color: textDark),
          bodyMedium:     TextStyle(color: textDarkSub),
          bodySmall:      TextStyle(color: textDarkMuted),
          labelLarge:     TextStyle(color: textDark, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Outfit',
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: bgCardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: borderLight, thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardWhiteEl,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        labelStyle: const TextStyle(color: textDarkSub),
        hintStyle: const TextStyle(color: textDarkMuted),
        prefixIconColor: textDarkMuted,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgCardWhite,
        indicatorColor: primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? primary : textDarkMuted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              color: s.contains(WidgetState.selected) ? primary : textDarkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? accent : textDarkMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? accent.withValues(alpha: 0.4)
                : borderLight),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgCardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
