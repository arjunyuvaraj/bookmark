import 'package:bookmark/screens/app_shell.dart';
import 'package:bookmark/screens/landing_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return AppShell();
    } else {
      return LandingScreen();
    }
  }
}
