import 'package:bookmark/components/custom_primary_button.dart';
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
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(25), width: 1),
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
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                ),
                          ),

                          const SizedBox(height: 48),

                          _infoBlock(context, label: 'USERNAME', value: name),

                          const SizedBox(height: 24),

                          _infoBlock(context, label: 'EMAIL', value: email),

                          const SizedBox(height: 40),

                          CustomPrimaryButton(
                            label: 'Change Password',
                            onTap: () => {
                              (user!.isAnonymous || email.isEmpty)
                                  ? null
                                  : () async {
                                      await FirebaseAuth.instance
                                          .sendPasswordResetEmail(email: email);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Password reset email sent.',
                                          ),
                                        ),
                                      );
                                    },
                            },
                          ),

                          const SizedBox(height: 20),

                          TextButton(
                            onPressed: () {
                              AuthenticationService().signOut(context);
                            },
                            child: Text(
                              'Sign Out',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withAlpha(150),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white.withAlpha(153),
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
            border: Border.all(color: Colors.white.withAlpha(40)),
            color: Colors.black.withAlpha(20),
          ),
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
