import 'package:bookmark/constants/routes.dart';
import 'package:bookmark/firebase_options.dart';
import 'package:bookmark/providers/theme_provider.dart';
import 'package:bookmark/theme/default_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

/// Example Gemini call (call this later, NOT in main)
Future<void> testGemini() async {
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-2.5-flash',
  );

  final prompt = [Content.text('Write a story about a magic backpack.')];

  final response = await model.generateContent(prompt);
  debugPrint(response.text);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bookmark',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      routes: routes,
      home: initialScreen,
      initialRoute: initialRoute,
      builder: (context, child) {
        return ThemeProviderInherited(
          provider: _themeProvider,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

// InheritedWidget to provide ThemeProvider down the widget tree
class ThemeProviderInherited extends InheritedWidget {
  final ThemeProvider provider;

  const ThemeProviderInherited({
    super.key,
    required this.provider,
    required super.child,
  });

  static ThemeProvider of(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ThemeProviderInherited>();
    return widget!.provider;
  }

  static ThemeProvider? maybeOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<ThemeProviderInherited>();
    return widget?.provider;
  }

  @override
  bool updateShouldNotify(ThemeProviderInherited oldWidget) {
    return provider.themeMode != oldWidget.provider.themeMode;
  }
}
