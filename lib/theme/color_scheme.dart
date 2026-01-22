import 'package:flutter/material.dart';

// Notion-style color scheme with dark and light mode support
// Accent color: RGB(0, 145, 255)
const Color accentBlue = Color.fromARGB(255, 0, 145, 255);
const Color primaryBlue = accentBlue;

// ============================================
// DARK THEME COLORS
// ============================================
const Color darkWhite = Color(0xFFFFFFFF);
const Color darkAlmostBlack = Color(0xFF0A0A0A);
const Color darkBlack = Color(0xFF202124);
const Color darkDarkGray = Color(0xFF1C1C1E);
const Color darkMediumGray = Color(0xFF2C2C2E);
const Color darkLightGray = Color(0xFF3A3A3C);
const Color darkBorderGray = Color(0xFF48484A);
const Color darkTextGray = Color(0xFF8E8E93);

// ============================================
// LIGHT THEME COLORS (Notion-style)
// ============================================
const Color lightWhite = Color(0xFFFFFFFF);
const Color lightBackground = Color(0xFFFFFFFF);
const Color lightSurface = Color(0xFFF7F6F3);
const Color lightSurfaceElevated = Color(0xFFFFFFFF);
const Color lightBorder = Color(0xFFE3E2DE);
const Color lightTextPrimary = Color(0xFF37352F);
const Color lightTextSecondary = Color(0xFF787774);
const Color lightTextTertiary = Color(0xFF9B9A97);

// ============================================
// THEME-AWARE COLOR GETTERS
// ============================================

// Dark theme colors
Color get darkPrimary => primaryBlue;
Color get darkOnPrimary => darkWhite;
Color get darkTertiary => accentBlue;
Color get darkBackground => darkAlmostBlack;
Color get darkSurface => darkDarkGray;
Color get darkSurfaceElevated => darkMediumGray;
Color get darkOnSurface => darkWhite;
Color get darkSecondary => darkTextGray;
Color get darkOutline => darkBorderGray;
Color get darkButtonBackground => accentBlue;
Color get darkButtonText => darkWhite;
Color get darkInputBackground => darkMediumGray;
Color get darkInputBorder => darkLightGray;
Color get darkInputFocusBorder => primaryBlue;

// Light theme colors
Color get lightPrimary => primaryBlue;
Color get lightOnPrimary => lightWhite;
Color get lightTertiary => accentBlue;
Color get lightOnSurface => lightTextPrimary;
Color get lightSecondary => lightTextSecondary;
Color get lightOutline => lightBorder;
Color get lightButtonBackground => accentBlue;
Color get lightButtonText => lightWhite;
Color get lightInputBackground => lightSurface;
Color get lightInputBorder => lightBorder;
Color get lightInputFocusBorder => primaryBlue;

// ============================================
// LEGACY EXPORTS (for backwards compatibility - dark theme)
// ============================================
Color primary = primaryBlue;
Color onPrimary = darkWhite;
Color tertiary = accentBlue;
Color background = darkAlmostBlack;
Color surface = darkDarkGray;
Color surfaceElevated = darkMediumGray;
Color onSurface = darkWhite;
Color secondary = darkTextGray;
Color outline = darkBorderGray;
Color buttonBackground = accentBlue;
Color buttonText = darkWhite;
Color inputBackground = darkMediumGray;
Color inputBorder = darkLightGray;
Color inputFocusBorder = primaryBlue;
const Color white = darkWhite;
const Color almostBlack = darkAlmostBlack;
const Color black = darkBlack;
const Color darkGray = darkDarkGray;
const Color mediumGray = darkMediumGray;
const Color lightGray = darkLightGray;
const Color borderGray = darkBorderGray;
const Color textGray = darkTextGray;

// ============================================
// COLOR SCHEMES
// ============================================

ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: darkPrimary,
  onPrimary: darkOnPrimary,
  secondary: darkSecondary,
  onSecondary: darkWhite,
  tertiary: darkTertiary,
  onTertiary: darkWhite,
  error: const Color(0xFFFF453A),
  onError: darkWhite,
  surface: darkSurface,
  onSurface: darkOnSurface,
);

ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: lightPrimary,
  onPrimary: lightOnPrimary,
  secondary: lightSecondary,
  onSecondary: lightTextPrimary,
  tertiary: lightTertiary,
  onTertiary: lightWhite,
  error: const Color(0xFFEB5757),
  onError: lightWhite,
  surface: lightSurface,
  onSurface: lightOnSurface,
);

// Legacy export for backwards compatibility
ColorScheme colorScheme = darkColorScheme;
