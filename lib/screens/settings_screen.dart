import 'package:bookmark/components/custom_primary_button.dart';
import 'package:bookmark/main.dart';
import 'package:bookmark/services/authentication_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Material(
          elevation: 8,
          shadowColor: Colors.black.withAlpha(75),
          borderRadius: BorderRadius.circular(24),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha(25)
                    : Colors.black.withAlpha(10),
                width: 1,
              ),
            ),
            child: uid == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data =
                          snapshot.data!.data() as Map<String, dynamic>?;

                      final email = data?['email'] ?? 'No email';
                      final name = user?.displayName ?? 'No username set';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Text(
                            'Settings',
                            textAlign: TextAlign.center,
                            style:
                                theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),

                          const SizedBox(height: 48),

                          _infoBlock(context, label: 'USERNAME', value: name),

                          const SizedBox(height: 24),

                          _infoBlock(context, label: 'EMAIL', value: email),

                          const SizedBox(height: 32),

                          // Theme toggle section
                          _ThemeToggle(),

                          const SizedBox(height: 32),

                          CustomPrimaryButton(
                            label: 'Change Password',
                            onTap: () => {
                              (user!.isAnonymous || email.isEmpty)
                                  ? null
                                  : AuthenticationService()
                                        .sendPasswordResetEmail(email, context),
                            },
                          ),

                          const SizedBox(height: 20),

                          TextButton(
                            onPressed: () {
                              AuthenticationService().signOut(context);
                            },
                            child: Text(
                              'Sign Out',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _infoBlock(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withAlpha(153),
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(40)
                  : Colors.black.withAlpha(15),
            ),
            color: isDark
                ? Colors.black.withAlpha(20)
                : Colors.white.withAlpha(200),
          ),
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = ThemeProviderInherited.maybeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APPEARANCE',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withAlpha(153),
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(40)
                  : Colors.black.withAlpha(15),
            ),
            color: isDark
                ? Colors.black.withAlpha(20)
                : Colors.white.withAlpha(200),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode_outlined,
                  isSelected: !isDark,
                  onTap: () => themeProvider?.setThemeMode(ThemeMode.light),
                ),
              ),
              Expanded(
                child: _ThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  isSelected: isDark,
                  onTap: () => themeProvider?.setThemeMode(ThemeMode.dark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withAlpha(153),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withAlpha(153),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
