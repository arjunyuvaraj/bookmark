import 'package:bookmark/theme/color_scheme.dart';
import 'package:bookmark/theme/text_theme.dart';
import 'package:bookmark/utilities/extensions.dart';
import 'package:flutter/material.dart';

class CustomSecondaryButton extends StatelessWidget {
  final String label;
  final GestureTapCallback onTap;

  const CustomSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        customBorder: Border.all(color: onSurface),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: onSurface, width: 2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: Text(
            label.capitalized,
            style: labelLarge.copyWith(
              color: onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
