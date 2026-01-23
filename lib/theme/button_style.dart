import 'package:bookmark/theme/color_scheme.dart';
import 'package:flutter/material.dart';

const double buttonRadius = 6.0;

// Notion-style primary button - bigger with more padding
ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryBlue,
  foregroundColor: white,
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  minimumSize: const Size(0, 44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
  elevation: 0,
  textStyle: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  ),
);

// Notion-style secondary button
ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.transparent,
  foregroundColor: lightTextPrimary,
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  minimumSize: const Size(0, 44),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(buttonRadius),
    side: BorderSide(color: lightBorder, width: 1),
  ),
  elevation: 0,
  textStyle: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  ),
);

// Large button variant for prominent actions
ButtonStyle largePrimaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: primaryBlue,
  foregroundColor: white,
  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
  minimumSize: const Size(0, 52),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
  elevation: 0,
  textStyle: const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  ),
);
