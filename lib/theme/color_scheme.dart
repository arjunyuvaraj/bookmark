import 'package:flutter/material.dart';

const Color accentBlue = Color(0xFF2383E2);
const Color primaryBlue = Color(0xFF2383E2);

// DARK THEME COLORS - Softer, warmer palette for better aesthetics
const Color darkBackground = Color(0xFF191919);
const Color darkSurface = Color(0xFF232323);
const Color darkSurfaceElevated = Color(0xFF2D2D2D);
const Color darkBorder = Color(0xFF333333);
const Color darkTextPrimary = Color(0xFFE8E8E8);
const Color darkTextSecondary = Color(0xFF999999);
const Color darkTextTertiary = Color(0xFF666666);

// LIGHT THEME COLORS - Clean Notion-style
const Color lightBackground = Color(0xFFFFFFFF);
const Color lightSurface = Color(0xFFFBFBFA);
const Color lightSurfaceElevated = Color(0xFFFFFFFF);
const Color lightBorder = Color(0xFFF0F0EF);
const Color lightTextPrimary = Color(0xFF37352F);
const Color lightTextSecondary = Color(0xFF787774);
const Color lightTextTertiary = Color(0xFF9B9A97);

// Dark theme getters
Color get darkPrimary => primaryBlue;
Color get darkOnPrimary => const Color(0xFFFFFFFF);
Color get darkTertiary => accentBlue;
Color get darkOnSurface => darkTextPrimary;
Color get darkSecondary => darkTextSecondary;
Color get darkOutline => darkBorder;

// Light theme getters
Color get lightPrimary => primaryBlue;
Color get lightOnPrimary => const Color(0xFFFFFFFF);
Color get lightTertiary => accentBlue;
Color get lightOnSurface => lightTextPrimary;
Color get lightSecondary => lightTextSecondary;
Color get lightOutline => lightBorder;

// Legacy exports
Color primary = primaryBlue;
Color onPrimary = const Color(0xFFFFFFFF);
Color tertiary = accentBlue;
Color background = darkBackground;
Color surface = darkSurface;
Color surfaceElevated = darkSurfaceElevated;
Color onSurface = darkTextPrimary;
Color secondary = darkTextSecondary;
Color outline = darkBorder;
const Color white = Color(0xFFFFFFFF);
const Color almostBlack = Color(0xFF191919);

// Legacy color names for backwards compatibility
const Color mediumGray = Color(0xFF787774);
const Color darkGray = Color(0xFF37352F);
const Color borderGray = Color(0xFFF0F0EF);
const Color textGray = Color(0xFF9B9A97);

ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: primaryBlue,
  onPrimary: const Color(0xFFFFFFFF),
  secondary: darkTextSecondary,
  onSecondary: const Color(0xFFFFFFFF),
  tertiary: accentBlue,
  onTertiary: const Color(0xFFFFFFFF),
  error: const Color(0xFFE57373),
  onError: const Color(0xFFFFFFFF),
  surface: darkSurface,
  onSurface: darkTextPrimary,
  outline: darkBorder,
);

ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: primaryBlue,
  onPrimary: const Color(0xFFFFFFFF),
  secondary: lightTextSecondary,
  onSecondary: lightTextPrimary,
  tertiary: accentBlue,
  onTertiary: const Color(0xFFFFFFFF),
  error: const Color(0xFFE57373),
  onError: const Color(0xFFFFFFFF),
  surface: lightSurface,
  onSurface: lightTextPrimary,
  outline: lightBorder,
);

ColorScheme colorScheme = lightColorScheme;
