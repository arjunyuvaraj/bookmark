import 'package:bookmark/constants/routes.dart';
import 'package:bookmark/screens/landing_screen.dart';
import 'package:bookmark/theme/default_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bookmark',
      home: const LandingScreen(),
      theme: theme,
      debugShowCheckedModeBanner: false,
      routes: routes,
    );
  }
}
