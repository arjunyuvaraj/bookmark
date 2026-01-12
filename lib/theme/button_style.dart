import 'package:bookmark/theme/color_scheme.dart';
import 'package:flutter/material.dart';

ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: buttonBackground,
  foregroundColor: buttonText,
  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 0,
  textStyle: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  ),
);

ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFF3C3C3E),
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
  ),
  elevation: 0,
);
