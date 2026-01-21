import 'package:bookmark/theme/button_style.dart';
import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/input_style.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:flutter/material.dart';

ThemeData theme = ThemeData(
  useMaterial3: true,
  colorScheme: colorScheme,
  scaffoldBackgroundColor: background,

  textTheme: TextTheme(
    displayLarge: displayLarge.copyWith(color: white),
    displayMedium: displayMedium.copyWith(color: white),
    displaySmall: displaySmall.copyWith(color: white),
    headlineLarge: headlineLarge.copyWith(color: white),
    headlineMedium: headlineMedium.copyWith(color: secondary),
    headlineSmall: headlineSmall.copyWith(color: white),
    titleLarge: titleLarge.copyWith(color: white),
    titleMedium: titleMedium.copyWith(color: white),
    titleSmall: titleSmall.copyWith(color: white),
    bodyLarge: bodyLarge.copyWith(color: white),
    bodyMedium: bodyMedium.copyWith(color: onSurface),
    bodySmall: bodySmall.copyWith(color: secondary),
    labelLarge: labelLarge.copyWith(color: white),
    labelMedium: labelMedium.copyWith(color: white),
    labelSmall: labelSmall.copyWith(color: secondary),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),

  appBarTheme: AppBarTheme(
    backgroundColor: background,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    foregroundColor: white,
  ),
  inputDecorationTheme: inputTheme,
  dividerColor: outline,
  cardColor: surface,
  dialogTheme: DialogThemeData(backgroundColor: surface),
);
