import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:bookmark/utilities/extensions.dart';
import 'package:flutter/material.dart';

double getLetterSpacing(int fontSize, double percentage) {
  return fontSize * percentage;
}

int getOpacity(double percentage) {
  return (255 * percentage).floor();
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> displayErrorToUser(
  String text,
  BuildContext context,
) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: surface.changeColorLightness(0.95),
      content: Text(
        text,
        textAlign: TextAlign.center,
        style: labelLarge.copyWith(
          color: tertiary.changeColorLightness(0.25),
          fontSize: 12,
          letterSpacing: getLetterSpacing(12, 0.10),
        ),
      ),
    ),
  );
}

Color changeColorHue(Color color, double newHueValue) =>
    HSLColor.fromColor(color).withHue(newHueValue).toColor();

Color changeColorSaturation(Color color, double newSaturationValue) =>
    HSLColor.fromColor(color).withSaturation(newSaturationValue).toColor();

Color changeColorLightness(Color color, double newLightnessValue) =>
    HSLColor.fromColor(color).withLightness(newLightnessValue).toColor();
