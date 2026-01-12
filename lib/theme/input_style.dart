import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:flutter/material.dart';

InputDecorationTheme inputTheme = InputDecorationTheme(
  filled: true,
  fillColor: inputBackground,
  floatingLabelBehavior: FloatingLabelBehavior.never,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
  hintStyle: bodyMedium.copyWith(color: Colors.white.withOpacity(0.3)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: inputBorder.withOpacity(0.3), width: 1),
    borderRadius: BorderRadius.circular(12),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: primary.withOpacity(0.5), width: 1.5),
    borderRadius: BorderRadius.circular(12),
  ),
);
