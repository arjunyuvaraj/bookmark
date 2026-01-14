import 'package:bookmark/screens/login_screen.dart';
import 'package:bookmark/screens/register_screen.dart';
import 'package:bookmark/screens/app_shell.dart';
import 'package:flutter/material.dart';

const String initialRoute = '/';
// const Widget initialScreen = LandingScreen();
const Widget initialScreen = LoginScreen();
Map<String, WidgetBuilder> routes = {
  '/login': (context) => const LoginScreen(),
  '/register': (context) => const RegisterScreen(),
  '/app': (context) => const AppShell(),
};
