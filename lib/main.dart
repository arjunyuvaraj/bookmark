import 'package:bookmark/constants/routes.dart';
import 'package:bookmark/firebase_options.dart';
import 'package:bookmark/theme/default_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'firebase_options.dart';
// Import the functions you need from the SDKs you need
// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
// const firebaseConfig = {
//   apiKey: "AIzaSyCrzmFEZSI0swDmbcYw9108Ag8iRyrEKr8",
//   authDomain: "bookmark-bca.firebaseapp.com",
//   projectId: "bookmark-bca",
//   storageBucket: "bookmark-bca.firebasestorage.app",
//   messagingSenderId: "153734490852",
//   appId: "1:153734490852:web:d1829d9a1f78959e609af1",
//   measurementId: "G-FDN836SXLH"
// };

// // Initialize Firebase
// const app = initializeApp(firebaseConfig);
// const analytics = getAnalytics(app);
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// Initialize the Gemini Developer API backend service
// Create a `GenerativeModel` instance with a model that supports your use case
final model =
      FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

// Provide a prompt that contains text
final prompt = [Content.text('Write a story about a magic backpack.')];

// To generate text output, call generateContent with the text input
// TODO: add await/async
final response = model.generateContent(prompt);
// print(response.text);

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
