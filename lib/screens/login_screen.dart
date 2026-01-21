import 'package:bookmark/components/custom_primary_button.dart';
import 'package:bookmark/components/custom_text_field.dart';
import 'package:bookmark/components/google_sign_in_button.dart';
import 'package:bookmark/services/authentication_service.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;
import 'package:flutter/material.dart';

// Notion-style radius
const double _cardRadius = 8.0;

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
    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 56,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(_cardRadius),
                  border: Border.all(color: colors.outline, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('app-icon.png', width: 24, height: 24),
                        const SizedBox(width: 16),
                        Text(
                          'bookmark',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                color: colors.white,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    GoogleSignInButton(
                      onTap: () {
                        AuthenticationService().signInWithGoogle(context);
                      },
                    ),

                    const SizedBox(height: 32),

                    // Divider with OR
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: colors.outline, thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colors.secondary,
                                  letterSpacing: 1.5,
                                ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: colors.outline, thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Email Label
                    Text(
                      'EMAIL',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email Input
                    CustomTextField(hintText: '', controller: emailController),

                    const SizedBox(height: 24),

                    // Password Label
                    Text(
                      'PASSWORD',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Password Input
                    CustomTextField(
                      hintText: '',
                      controller: passwordController,
                      obscureText: true,
                    ),

                    const SizedBox(height: 32),

                    // Sign In Button
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

                    const SizedBox(height: 20),

                    // Footer Links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Handle forgot password
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.secondary),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Need an account? ',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.secondary),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/register',
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign Up',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
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
