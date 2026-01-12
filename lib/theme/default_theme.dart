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
    displayLarge: displayLarge.copyWith(color: primary),
    headlineMedium: headlineMedium,
    bodyMedium: bodyMedium.copyWith(color: onSurface),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  inputDecorationTheme: inputTheme,
  dividerColor: outline,
);
