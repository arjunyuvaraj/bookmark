import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookmark/components/upload_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UploadDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'there';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Upload button
                  _UploadButton(onPressed: () => _showUploadDialog(context)),
                ],
              ),

              const SizedBox(height: 48),

              // Quick actions section
              Text(
                'Quick actions',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(102),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  _QuickActionCard(
                    icon: Icons.upload_file_outlined,
                    title: 'Upload',
                    subtitle: 'Add new content',
                    onTap: () => _showUploadDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _UploadButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Upload'),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withAlpha(51),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
