import 'package:bookmark/components/custom_primary_button.dart';
import 'package:bookmark/components/custom_text_field.dart';
import 'package:bookmark/components/google_sign_in_button.dart';
import 'package:flutter/material.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1A4D5C), const Color(0xFF0D2931)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black.withAlpha(75),
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 56,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withAlpha(25),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo and Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('app_icon.png', width: 48, height: 48),
                            const SizedBox(width: 16),
                            Text(
                              'bookmark',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Google Sign In Button
                        GoogleSignInButton(
                          onTap: () {
                            // Handle Google sign in
                          },
                        ),

                        const SizedBox(height: 32),

                        // Divider with OR
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.white.withAlpha(50),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'OR',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.white.withAlpha(128),
                                      letterSpacing: 1.5,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.white.withAlpha(50),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Email Label
                        Text(
                          'EMAIL',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withAlpha(153),
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Email Input
                        CustomTextField(
                          hintText: '',
                          controller: emailController,
                        ),

                        const SizedBox(height: 24),

                        // Password Label
                        Text(
                          'PASSWORD',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withAlpha(153),
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
                        // Email Label
                        Text(
                          'CONFIRM PASSWORD',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withAlpha(153),
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                        ),
                        const SizedBox(height: 8),

                        // Email Input
                        CustomTextField(
                          hintText: '',
                          controller: confirmPasswordController,
                        ),

                        const SizedBox(height: 24),
                        // Sign In Button
                        CustomPrimaryButton(
                          label: "Register",
                          onTap: () {
                            // Handle sign in
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
                                    ?.copyWith(
                                      color: Colors.white.withAlpha(150),
                                    ),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Need an account? ',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withAlpha(150),
                                      ),
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
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
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
        ),
      ),
    );
  }
}
