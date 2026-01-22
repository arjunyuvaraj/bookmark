import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmark/utilities/helper_functions.dart';

// All text styles use Inter for a clean, modern Notion-like look
// No serif fonts - clean sans-serif throughout

final displayLarge = GoogleFonts.inter(
  fontSize: 72,
  fontWeight: FontWeight.w600,
  letterSpacing: getLetterSpacing(72, -0.02),
  height: 1.05,
);

final displayMedium = GoogleFonts.inter(
  fontSize: 56,
  fontWeight: FontWeight.w600,
  letterSpacing: getLetterSpacing(56, -0.02),
);

final displaySmall = GoogleFonts.inter(
  fontSize: 44,
  fontWeight: FontWeight.w600,
  letterSpacing: getLetterSpacing(44, -0.01),
);

final headlineLarge = GoogleFonts.inter(
  fontSize: 36,
  fontWeight: FontWeight.w600,
);

final headlineMedium = GoogleFonts.inter(
  fontSize: 20,
  fontWeight: FontWeight.w500,
  letterSpacing: getLetterSpacing(20, 0.02),
);

final headlineSmall = GoogleFonts.inter(
  fontSize: 18,
  fontWeight: FontWeight.w500,
);

final titleLarge = GoogleFonts.inter(
  fontSize: 24,
  fontWeight: FontWeight.w600,
);

final titleMedium = GoogleFonts.inter(
  fontSize: 20,
  fontWeight: FontWeight.w500,
);

final titleSmall = GoogleFonts.inter(
  fontSize: 18,
  fontWeight: FontWeight.w500,
);

final labelLarge = GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  letterSpacing: getLetterSpacing(16, 0.08),
);

final labelMedium = GoogleFonts.inter(
  fontSize: 14,
  fontWeight: FontWeight.w500,
);

final labelSmall = GoogleFonts.inter(
  fontSize: 13,
  fontWeight: FontWeight.w500,
  letterSpacing: getLetterSpacing(13, 0.12),
);

final bodyLarge = GoogleFonts.inter(
  fontSize: 18,
  fontWeight: FontWeight.w400,
  height: 1.55,
);

final bodyMedium = GoogleFonts.inter(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.5,
);

final bodySmall = GoogleFonts.inter(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.45,
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
