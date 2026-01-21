import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:flutter/material.dart';

// Notion-style input radius
const double inputRadius = 8.0;

InputDecorationTheme inputTheme = InputDecorationTheme(
  filled: true,
  fillColor: inputBackground,
  floatingLabelBehavior: FloatingLabelBehavior.never,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(inputRadius),
    borderSide: BorderSide(color: inputBorder, width: 1),
  ),
  hintStyle: bodyMedium.copyWith(color: secondary),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorder, width: 1),
    borderRadius: BorderRadius.circular(inputRadius),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: primary, width: 1.5),
    borderRadius: BorderRadius.circular(inputRadius),
  ),
);
