import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;
import 'package:bookmark/components/upload_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UploadDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _showUploadDialog(context),
        icon: const Icon(Icons.upload),
        label: Text(
          'Upload',
          style: GoogleFonts.instrumentSerif(
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.white,
          foregroundColor: colors.darkGray,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
