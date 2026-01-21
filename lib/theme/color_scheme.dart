import 'package:flutter/material.dart';

// Notion-style monochromatic color scheme
// Accent color: RGB(0, 145, 255)
const Color accentBlue = Color.fromARGB(255, 0, 145, 255);

// Monochromatic colors (whites, grays, blacks)
const Color white = Color(0xFFFFFFFF);
const Color offWhite = Color(0xFFFAFAFA);
const Color lightGray = Color(0xFFEBEBEB);
const Color mediumGray = Color(0xFF9B9B9B);
const Color darkGray = Color(0xFF37352F);
const Color black = Color(0xFF191919);

// Primary colors
Color primary = accentBlue;
Color onPrimary = white;
Color tertiary = accentBlue;

// Background colors (dark theme - Notion dark mode style)
Color background = black;
Color surface = const Color(0xFF252525);
Color onSurface = white;

// Secondary/muted text
Color secondary = mediumGray;
Color outline = const Color(0xFF3A3A3A);

// Button colors
Color buttonBackground = accentBlue;
Color buttonText = white;

// Input colors
Color inputBackground = const Color(0xFF2F2F2F);
Color inputBorder = const Color(0xFF3A3A3A);

// Legacy alias for compatibility
const Color primaryBlue = accentBlue;

ColorScheme colorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: primary,
  onPrimary: onPrimary,
  secondary: secondary,
  onSecondary: onPrimary,
  tertiary: tertiary,
  onTertiary: Colors.white,
  error: const Color(0xFFEB5757),
  onError: Colors.white,
  surface: surface,
  onSurface: onSurface,
);
