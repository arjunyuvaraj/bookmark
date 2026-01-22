import 'package:bookmark/theme/button_style.dart';
import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/input_style.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:flutter/material.dart';

// Dark Theme
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: darkBackground,

  textTheme: TextTheme(
    displayLarge: displayLarge.copyWith(color: darkWhite),
    displayMedium: displayMedium.copyWith(color: darkWhite),
    displaySmall: displaySmall.copyWith(color: darkWhite),
    headlineLarge: headlineLarge.copyWith(color: darkWhite),
    headlineMedium: headlineMedium.copyWith(color: darkSecondary),
    headlineSmall: headlineSmall.copyWith(color: darkWhite),
    titleLarge: titleLarge.copyWith(color: darkWhite),
    titleMedium: titleMedium.copyWith(color: darkWhite),
    titleSmall: titleSmall.copyWith(color: darkWhite),
    bodyLarge: bodyLarge.copyWith(color: darkWhite),
    bodyMedium: bodyMedium.copyWith(color: darkOnSurface),
    bodySmall: bodySmall.copyWith(color: darkSecondary),
    labelLarge: labelLarge.copyWith(color: darkWhite),
    labelMedium: labelMedium.copyWith(color: darkWhite),
    labelSmall: labelSmall.copyWith(color: darkSecondary),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),

  appBarTheme: AppBarTheme(
    backgroundColor: darkBackground,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    foregroundColor: darkWhite,
  ),
  inputDecorationTheme: inputTheme,
  dividerColor: darkOutline,
  cardColor: darkSurface,
  dialogTheme: DialogThemeData(backgroundColor: darkSurface),
);

// Light Theme
ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  scaffoldBackgroundColor: lightBackground,

  textTheme: TextTheme(
    displayLarge: displayLarge.copyWith(color: lightTextPrimary),
    displayMedium: displayMedium.copyWith(color: lightTextPrimary),
    displaySmall: displaySmall.copyWith(color: lightTextPrimary),
    headlineLarge: headlineLarge.copyWith(color: lightTextPrimary),
    headlineMedium: headlineMedium.copyWith(color: lightTextSecondary),
    headlineSmall: headlineSmall.copyWith(color: lightTextPrimary),
    titleLarge: titleLarge.copyWith(color: lightTextPrimary),
    titleMedium: titleMedium.copyWith(color: lightTextPrimary),
    titleSmall: titleSmall.copyWith(color: lightTextPrimary),
    bodyLarge: bodyLarge.copyWith(color: lightTextPrimary),
    bodyMedium: bodyMedium.copyWith(color: lightOnSurface),
    bodySmall: bodySmall.copyWith(color: lightTextSecondary),
    labelLarge: labelLarge.copyWith(color: lightTextPrimary),
    labelMedium: labelMedium.copyWith(color: lightTextPrimary),
    labelSmall: labelSmall.copyWith(color: lightTextSecondary),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),

  appBarTheme: AppBarTheme(
    backgroundColor: lightBackground,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    foregroundColor: lightTextPrimary,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: lightInputBackground,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: lightInputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: lightInputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: lightInputFocusBorder, width: 2),
    ),
    hintStyle: TextStyle(color: lightTextTertiary),
  ),
  dividerColor: lightOutline,
  cardColor: lightSurfaceElevated,
  dialogTheme: DialogThemeData(backgroundColor: lightSurfaceElevated),
);

// Legacy export for backwards compatibility
ThemeData theme = darkTheme;
