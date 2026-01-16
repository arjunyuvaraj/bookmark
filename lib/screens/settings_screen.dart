import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 200, vertical: 100),
          decoration: BoxDecoration(border: Border.all(color: Colors.white)),
          child: Text(
            'Settings',
            style: GoogleFonts.instrumentSerif(
              color: colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
