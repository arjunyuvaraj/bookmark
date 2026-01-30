import 'package:bookmark/components/custom_primary_button.dart';
import 'package:bookmark/components/custom_text_field.dart';
import 'package:bookmark/components/google_sign_in_button.dart';
import 'package:bookmark/services/authentication_service.dart';
import 'package:bookmark/utilities/helper_functions.dart';
import 'package:bookmark/theme/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const double _cardRadius = 8.0;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final logoColor = isDark ? darkTextPrimary : lightTextPrimary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(_cardRadius),
                  border: Border.all(color: colorScheme.outline.withAlpha(isDark ? 255 : 51), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/bookmark-logo.svg',
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 14),
                        Text('bookmark', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 48),
                    GoogleSignInButton(onTap: () => AuthenticationService().signInWithGoogle(context)),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(child: Divider(color: colorScheme.outline.withAlpha(isDark ? 255 : 51), thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OR', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(153), letterSpacing: 1.5)),
                        ),
                        Expanded(child: Divider(color: colorScheme.outline.withAlpha(isDark ? 255 : 51), thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('EMAIL', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(153), fontSize: 11, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    CustomTextField(hintText: '', controller: emailController),
                    const SizedBox(height: 24),
                    Text('PASSWORD', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(153), fontSize: 11, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    CustomTextField(hintText: '', controller: passwordController, obscureText: true),
                    const SizedBox(height: 24),
                    Text('CONFIRM PASSWORD', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withAlpha(153), fontSize: 11, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    CustomTextField(hintText: '', controller: confirmPasswordController, obscureText: true),
                    const SizedBox(height: 24),
                    CustomPrimaryButton(
                      label: "Register",
                      onTap: () {
                        if (passwordController.text == confirmPasswordController.text) {
                          AuthenticationService().signUpWithEmail(emailController.text, passwordController.text, context);
                        } else {
                          displayErrorToUser("Your passwords do not match", context);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withAlpha(153))),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('Log In', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
