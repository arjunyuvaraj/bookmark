import 'package:flutter/material.dart';

extension StringCasing on String {
  String get capitalized => isEmpty ? this : toUpperCase();
  String get lowercase => isEmpty ? this : toLowerCase();
  String get titleCase => split(' ').map((word) => word.capitalized).join(' ');
}

extension ColorProperties on Color {
  Color changeColorHue(double newHueValue) =>
      HSLColor.fromColor(this).withHue(newHueValue).toColor();

  Color changeColorSaturation(double newSaturationValue) =>
      HSLColor.fromColor(this).withSaturation(newSaturationValue).toColor();

  Color changeColorLightness(double newLightnessValue) =>
      HSLColor.fromColor(this).withLightness(newLightnessValue).toColor();
  Color withOpacity(double newOpacity) => withAlpha((newOpacity * 255) as int);
}
