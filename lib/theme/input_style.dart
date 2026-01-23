import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:flutter/material.dart';

const double inputRadius = 6.0;

InputDecorationTheme lightInputTheme = InputDecorationTheme(
  filled: true,
  fillColor: lightSurface,
  floatingLabelBehavior: FloatingLabelBehavior.never,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(inputRadius),
    borderSide: BorderSide(color: lightBorder, width: 1),
  ),
  hintStyle: bodyMedium.copyWith(color: lightTextSecondary),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: lightBorder, width: 1),
    borderRadius: BorderRadius.circular(inputRadius),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: primaryBlue, width: 1.5),
    borderRadius: BorderRadius.circular(inputRadius),
  ),
);

InputDecorationTheme darkInputTheme = InputDecorationTheme(
  filled: true,
  fillColor: darkSurface,
  floatingLabelBehavior: FloatingLabelBehavior.never,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(inputRadius),
    borderSide: BorderSide(color: darkBorder, width: 1),
  ),
  hintStyle: bodyMedium.copyWith(color: darkTextSecondary),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: darkBorder, width: 1),
    borderRadius: BorderRadius.circular(inputRadius),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: primaryBlue, width: 1.5),
    borderRadius: BorderRadius.circular(inputRadius),
  ),
);

// Legacy export for backwards compatibility
InputDecorationTheme inputTheme = lightInputTheme;
