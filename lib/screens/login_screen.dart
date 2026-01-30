import 'package:bookmark/components/custom_primary_button.dart';
import 'package:bookmark/components/custom_text_field.dart';
import 'package:bookmark/components/google_sign_in_button.dart';
import 'package:bookmark/services/authentication_service.dart';
import 'package:bookmark/theme/color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/bookmark-logo.svg',
                        width: 28,
                        height: 28,
                        colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 12),
                      Text('bookmark', style: theme.textTheme.headlineLarge),
                    ],
                  ),
                  const SizedBox(height: 56),
                  GoogleSignInButton(
                    onTap: () {
                      AuthenticationService().signInWithGoogle(context);
                    },
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(child: Divider(color: colorScheme.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'or',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withAlpha(102),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colorScheme.outline)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Email',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(hintText: '', controller: emailController),
                  const SizedBox(height: 24),
                  Text(
                    'Password',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    hintText: '',
                    controller: passwordController,
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  CustomPrimaryButton(
                    label: "Sign In",
                    onTap: () {
                      AuthenticationService().signInWithEmail(
                        emailController.text,
                        passwordController.text,
                        context,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Need an account? ',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: Text(
                          'Sign Up',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
