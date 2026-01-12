import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:bookmark/utilities/extensions.dart';
import 'package:flutter/material.dart';

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
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            label.capitalized,
            style: labelLarge.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
