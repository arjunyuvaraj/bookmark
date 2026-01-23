import 'package:flutter/material.dart';

const double _buttonRadius = 6.0;

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;

  const GoogleSignInButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_buttonRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(_buttonRadius),
            border: Border.all(color: colorScheme.outline, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/google-logo.png',
                width: 20,
                height: 20,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.g_mobiledata,
                  size: 24,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Continue with Google',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
