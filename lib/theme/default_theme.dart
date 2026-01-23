import 'package:bookmark/theme/button_style.dart';
import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: darkBackground,
  textTheme: TextTheme(
    displayLarge: displayLarge.copyWith(color: darkTextPrimary),
    displayMedium: displayMedium.copyWith(color: darkTextPrimary),
    displaySmall: displaySmall.copyWith(color: darkTextPrimary),
    headlineLarge: headlineLarge.copyWith(color: darkTextPrimary),
    headlineMedium: headlineMedium.copyWith(color: darkTextSecondary),
    headlineSmall: headlineSmall.copyWith(color: darkTextPrimary),
    titleLarge: titleLarge.copyWith(color: darkTextPrimary),
    titleMedium: titleMedium.copyWith(color: darkTextPrimary),
    titleSmall: titleSmall.copyWith(color: darkTextPrimary),
    bodyLarge: bodyLarge.copyWith(color: darkTextPrimary),
    bodyMedium: bodyMedium.copyWith(color: darkTextPrimary),
    bodySmall: bodySmall.copyWith(color: darkTextSecondary),
    labelLarge: labelLarge.copyWith(color: darkTextPrimary),
    labelMedium: labelMedium.copyWith(color: darkTextPrimary),
    labelSmall: labelSmall.copyWith(color: darkTextSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
  appBarTheme: AppBarTheme(
    backgroundColor: darkBackground,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    foregroundColor: darkTextPrimary,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryBlue, width: 2),
    ),
    hintStyle: TextStyle(color: darkTextTertiary),
  ),
  dividerColor: darkBorder,
  cardColor: darkSurface,
  cardTheme: CardThemeData(
    color: darkSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: darkSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

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
    bodyMedium: bodyMedium.copyWith(color: lightTextPrimary),
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
    fillColor: lightSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: primaryBlue, width: 2),
    ),
    hintStyle: TextStyle(color: lightTextTertiary),
  ),
  dividerColor: lightBorder,
  cardColor: lightSurfaceElevated,
  cardTheme: CardThemeData(
    color: lightSurfaceElevated,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: lightSurfaceElevated,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

ThemeData theme = lightTheme;
