import 'package:flutter/material.dart';

// Primary blue accent
const Color primaryBlue = Color(0xFF0A84FF); // Bright, modern blue
const Color primaryBlueDark = Color(0xFF0066CC);
const Color primaryBlueLight = Color(0xFF4DA2FF);

// Black and white base
const Color black = Color(0xFF000000);
const Color white = Color(0xFFFFFFFF);
const Color almostBlack = Color(0xFF0A0A0A);
const Color darkGray = Color(0xFF1C1C1E);
const Color mediumGray = Color(0xFF2C2C2E);
const Color lightGray = Color(0xFF3A3A3C);
const Color borderGray = Color(0xFF48484A);
const Color textGray = Color(0xFF8E8E93);

// Theme colors
Color primary = primaryBlue;
Color onPrimary = white;
Color tertiary = primaryBlue;

Color background = almostBlack;
Color surface = darkGray;
Color surfaceElevated = mediumGray;
Color onSurface = white;

Color secondary = textGray;
Color outline = borderGray;

Color buttonBackground = primaryBlue;
Color buttonText = white;

Color inputBackground = mediumGray;
Color inputBorder = lightGray;
Color inputFocusBorder = primaryBlue;

ColorScheme colorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: primary,
  onPrimary: onPrimary,
  secondary: secondary,
  onSecondary: white,
  tertiary: tertiary,
  onTertiary: white,
  error: const Color(0xFFFF453A),
  onError: white,
  surface: surface,
  onSurface: onSurface,
);
