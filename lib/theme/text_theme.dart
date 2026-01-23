import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Notion-style typography - clean Inter throughout with proper kerning
final displayLarge = GoogleFonts.inter(
  fontSize: 72,
  fontWeight: FontWeight.w700,
  letterSpacing: -2.5,
  height: 1.05,
);

final displayMedium = GoogleFonts.inter(
  fontSize: 56,
  fontWeight: FontWeight.w700,
  letterSpacing: -1.5,
  height: 1.1,
);

final displaySmall = GoogleFonts.inter(
  fontSize: 44,
  fontWeight: FontWeight.w700,
  letterSpacing: -1.0,
  height: 1.15,
);

final headlineLarge = GoogleFonts.inter(
  fontSize: 32,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.8,
  height: 1.2,
);

final headlineMedium = GoogleFonts.inter(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.5,
  height: 1.25,
);

final headlineSmall = GoogleFonts.inter(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.3,
  height: 1.3,
);

final titleLarge = GoogleFonts.inter(
  fontSize: 22,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.3,
  height: 1.3,
);

final titleMedium = GoogleFonts.inter(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.2,
  height: 1.35,
);

final titleSmall = GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.1,
  height: 1.4,
);

final labelLarge = GoogleFonts.inter(
  fontSize: 15,
  fontWeight: FontWeight.w500,
  letterSpacing: 0,
  height: 1.4,
);

final labelMedium = GoogleFonts.inter(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  letterSpacing: 0,
  height: 1.4,
);

final labelSmall = GoogleFonts.inter(
  fontSize: 12,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.1,
  height: 1.4,
);

final bodyLarge = GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.6,
);

final bodyMedium = GoogleFonts.inter(
  fontSize: 15,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.55,
);

final bodySmall = GoogleFonts.inter(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.5,
);

TextTheme textTheme = TextTheme(
  displayLarge: displayLarge,
  displayMedium: displayMedium,
  displaySmall: displaySmall,
  headlineLarge: headlineLarge,
  headlineMedium: headlineMedium,
  headlineSmall: headlineSmall,
  titleLarge: titleLarge,
  titleMedium: titleMedium,
  titleSmall: titleSmall,
  labelLarge: labelLarge,
  labelMedium: labelMedium,
  labelSmall: labelSmall,
  bodyLarge: bodyLarge,
  bodyMedium: bodyMedium,
  bodySmall: bodySmall,
);
