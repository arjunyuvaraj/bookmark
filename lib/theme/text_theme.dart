import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/utilities/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final displayLarge = GoogleFonts.ibmPlexMono(
  fontSize: 72,
  fontWeight: FontWeight.w500,
  letterSpacing: getLetterSpacing(72, -0.02),
  height: 1.05,
  color: primary,
);

final displayMedium = GoogleFonts.instrumentSerif(
  fontSize: 56,
  fontWeight: FontWeight.w400,
  letterSpacing: getLetterSpacing(56, -0.02),
);

final displaySmall = GoogleFonts.instrumentSerif(
  fontSize: 44,
  fontWeight: FontWeight.w400,
);

final headlineLarge = GoogleFonts.instrumentSerif(
  fontSize: 36,
  fontWeight: FontWeight.w400,
);

final headlineMedium = GoogleFonts.inter(
  fontSize: 20,
  fontWeight: FontWeight.w400,
  color: secondary,
  letterSpacing: getLetterSpacing(20, 0.02),
);

final headlineSmall = GoogleFonts.inter(
  fontSize: 18,
  fontWeight: FontWeight.w400,
);

final titleLarge = GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w500);

final titleMedium = GoogleFonts.inter(
  fontSize: 20,
  fontWeight: FontWeight.w500,
);

final titleSmall = GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500);

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
  color: tertiary,
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
