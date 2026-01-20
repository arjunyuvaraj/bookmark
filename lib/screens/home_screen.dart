import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;
import 'package:bookmark/models/study_set.dart';
import 'package:bookmark/screens/study_set_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isAnalyzing = false;

  Future<void> _showFileTypeDialog() async {
    final fileType = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload a file to analyze',
              style: GoogleFonts.instrumentSerif(
                color: colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select the type of file you want to upload',
              style: TextStyle(
                color: colors.secondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _FileTypeOption(
              icon: Icons.picture_as_pdf,
              title: 'PDF Document',
              subtitle: 'Upload a PDF file',
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
            const SizedBox(height: 12),
            _FileTypeOption(
              icon: Icons.text_snippet,
              title: 'Text File',
              subtitle: 'Upload a TXT file',
              onTap: () => Navigator.pop(context, 'txt'),
            ),
            const SizedBox(height: 12),
            _FileTypeOption(
              icon: Icons.image,
              title: 'Image',
              subtitle: 'Upload PNG, JPG, or JPEG',
              onTap: () => Navigator.pop(context, 'image'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (fileType != null) {
      await _pickAndAnalyzeFile(fileType);
    }
  }

  Future<void> _pickAndAnalyzeFile(String fileType) async {
    FileType pickerType;
    List<String>? allowedExtensions;

    switch (fileType) {
      case 'pdf':
        pickerType = FileType.custom;
        allowedExtensions = ['pdf'];
        break;
      case 'txt':
        pickerType = FileType.custom;
        allowedExtensions = ['txt'];
        break;
      case 'image':
        pickerType = FileType.image;
        break;
      default:
        return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: pickerType,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      await _analyzeFile(file, fileType);
    }
  }

  // Template IDs - create these in Firebase Console → AI Logic → Prompts
  static const String _imageTemplateId = 'image-analyzer';
  static const String _pdfTemplateId = 'pdf-analyzer';
  static const String _textTemplateId = 'text-analyzer';

  Future<void> _analyzeFile(File file, String fileType) async {
    setState(() => _isAnalyzing = true);

    try {
      final model = FirebaseAI.googleAI().templateGenerativeModel();

      String templateId;
      Map<String, dynamic> inputs = {};

      if (fileType == 'image') {
        templateId = _imageTemplateId;
        final bytes = await file.readAsBytes();
        final mimeType = file.path.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';
        inputs['image'] = InlineDataPart(mimeType, bytes);
      } else if (fileType == 'txt') {
        templateId = _textTemplateId;
        final content = await file.readAsString();
        inputs['content'] = content;
      } else if (fileType == 'pdf') {
        templateId = _pdfTemplateId;
        final bytes = await file.readAsBytes();
        inputs['document'] = InlineDataPart('application/pdf', bytes);
      } else {
        return;
      }

      final response = await model.generateContent(
        templateId,
        inputs: inputs,
      );

      if (mounted) {
        final responseText = response.text ?? '';
        _handleAnalysisResponse(responseText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _handleAnalysisResponse(String responseText) {
    try {
      // Try to extract JSON from the response
      // The response might have markdown code blocks or extra text
      String jsonStr = responseText;

      // Remove markdown code blocks if present
      final jsonMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(responseText);
      if (jsonMatch != null) {
        jsonStr = jsonMatch.group(1) ?? responseText;
      }

      // Try to find JSON object in the response
      final startIndex = jsonStr.indexOf('{');
      final endIndex = jsonStr.lastIndexOf('}');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        jsonStr = jsonStr.substring(startIndex, endIndex + 1);
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final studySet = StudySet.fromJson(json);

      if (studySet.flashcards.isEmpty && studySet.quiz.isEmpty) {
        _showRawAnalysisResult(responseText);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudySetScreen(
            studySet: studySet,
            title: 'Generated Study Set',
          ),
        ),
      );
    } catch (e) {
      // If JSON parsing fails, show the raw response
      _showRawAnalysisResult(responseText);
    }
  }

  void _showRawAnalysisResult(String analysis) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Analysis Result',
                    style: GoogleFonts.instrumentSerif(
                      color: colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    analysis,
                    style: TextStyle(
                      color: colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _isAnalyzing
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: colors.primaryBlue),
                const SizedBox(height: 16),
                Text(
                  'Analyzing...',
                  style: GoogleFonts.instrumentSerif(
                    color: colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            )
          : ElevatedButton.icon(
              onPressed: _showFileTypeDialog,
              icon: const Icon(Icons.upload),
              label: Text(
                'Upload',
                style: GoogleFonts.instrumentSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.white,
                foregroundColor: colors.darkGray,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
    );
  }
}

class _FileTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FileTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.secondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
