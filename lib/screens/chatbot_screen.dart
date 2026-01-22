import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Chatbot',
        style: GoogleFonts.instrumentSerif(
          color: colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}