import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:bookmark/utilities/extensions.dart';
import 'package:flutter/material.dart';

// Notion-style button radius
const double _buttonRadius = 8.0;

class CustomPrimaryButton extends StatelessWidget {
  final String label;
  final GestureTapCallback onTap;

  const CustomPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: primary,
      borderRadius: BorderRadius.circular(_buttonRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_buttonRadius),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          alignment: Alignment.center,
          child: Text(
            label.capitalized,
            style: labelLarge.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 15,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
