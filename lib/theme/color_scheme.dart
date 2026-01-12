import 'package:flutter/material.dart';

// Core
Color primary = const Color(0xFFFFFFFF);
Color onPrimary = const Color(0xFF0F0F0F);
Color tertiary = const Color(0xFF8D6BEB);

Color background = const Color(0xFF1A1A1A);
Color surface = const Color(0xFF2C2C2E);
Color onSurface = const Color(0xFFEDEDED);

// Accents
Color secondary = const Color(0xFFBDBDBD);
Color outline = const Color(0xFF3A3A3A);

// Buttons
Color buttonBackground = const Color(0xFFFFFFFF);
Color buttonText = const Color(0xFF111111);

// Input fields - darker background
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
