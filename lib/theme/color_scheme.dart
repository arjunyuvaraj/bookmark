import 'package:flutter/material.dart';

const Color primaryBlue = Color.fromARGB(0, 0, 145, 255);
const Color darkGray = Color(0xFF202124);
const Color white = Color(0xFFFFFFFF);

Color primary = primaryBlue;
Color onPrimary = white;
Color tertiary = primaryBlue;

Color background = darkGray;
Color surface = const Color(0xFF2C2C2E);
Color onSurface = white;

Color secondary = const Color(0xFFBDBDBD);
Color outline = const Color(0xFF3A3A3A);

Color buttonBackground = primaryBlue;
Color buttonText = white;

Color inputBackground = const Color(0xFF3C3C3E);
Color inputBorder = const Color(0xFF4A4A4C);

ColorScheme colorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: primary,
  onPrimary: onPrimary,
  secondary: secondary,
  onSecondary: onPrimary,
  tertiary: tertiary,
  onTertiary: Colors.white,
  error: Colors.red,
  onError: Colors.white,
  surface: surface,
  onSurface: onSurface,
);
