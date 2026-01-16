import 'package:bookmark/constants/routes.dart';
import 'package:bookmark/firebase_options.dart';
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'bookmark',
      theme: theme,
      debugShowCheckedModeBanner: false,
      routes: routes,
      home: initialScreen,
      initialRoute: initialRoute,
    );
  }
}
