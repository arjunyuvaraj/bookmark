import 'package:bookmark/theme/color_scheme.dart';
import 'package:flutter/material.dart';

// Notion-style button radius - slightly rounded rectangles
const double buttonRadius = 8.0;

ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: buttonBackground,
  foregroundColor: buttonText,
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
  elevation: 0,
  textStyle: const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  ),
);

ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.transparent,
  foregroundColor: white,
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(buttonRadius),
    side: BorderSide(color: outline, width: 1),
  ),
  elevation: 0,
  textStyle: const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  ),
);
