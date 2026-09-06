import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MandiSense design tokens and theme configuration.
///
/// Primary: Deep green (#2E7D32) — agriculture / trust
/// Accent:  Warm amber (#F9A825) — highlights & CTAs
class AppTheme {
  AppTheme._();

  // ── Colours ──────────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryGreenLight = Color(0xFF4CAF50);
  static const Color primaryGreenDark = Color(0xFF1B5E20);

  static const Color accentAmber = Color(0xFFF9A825);
  static const Color accentAmberLight = Color(0xFFFDD835);

  static const Color surfaceWhite = Color(0xFFFAFAFA);
  static const Color cardWhite = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);

  static const Color trendRising = Color(0xFF2E7D32);
  static const Color trendFalling = Color(0xFFC62828);
  static const Color trendStable = Color(0xFF757575);

  static const Color offlineBanner = Color(0xFFFFF8E1);
  static const Color offlineBannerText = Color(0xFFF57F17);

  // ── Card styling ─────────────────────────────────────────────────
  static const double cardRadius = 12.0;
  static const double cardElevation = 2.0;
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  static RoundedRectangleBorder get cardShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      );

  static BoxDecoration cardDecoration({Color? borderColor}) => BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(cardRadius),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  // ── Text Styles ──────────────────────────────────────────────────
  static TextStyle get headline => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      );

  static TextStyle get title => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle get bigNumber => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: primaryGreen,
      );

  // ── ThemeData ────────────────────────────────────────────────────
  static ThemeData getTheme(bool isSimpleMode) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentAmber,
        surface: surfaceWhite,
      ),
      scaffoldBackgroundColor: surfaceWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: isSimpleMode ? 28 : 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: cardElevation,
        shape: cardShape,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: isSimpleMode ? 22 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(),
    );

    return baseTheme;
  }

  static ThemeData get lightTheme => getTheme(false);
}
