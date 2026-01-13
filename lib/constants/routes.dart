import 'package:bookmark/screens/landing_screen.dart';
import 'package:bookmark/screens/login_screen.dart';
import 'package:flutter/material.dart';

const String initialRoute = '/';
const Widget initialScreen = LandingScreen();
Map<String, WidgetBuilder> routes = {
  '/login': (context) => const LoginScreen(),
};
