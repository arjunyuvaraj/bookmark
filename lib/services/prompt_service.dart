import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

/// Prompt for generating notes from content
const String _notesPrompt = '''
You are an expert note-taker creating comprehensive, well-organized study notes.

TASK: Create detailed study notes from the provided content in an organized, learnable format.

OUTPUT: Return ONLY a valid JSON object (no markdown fences):

{"title": "Topic title", "subject": "Subject area", "notes": "Markdown notes content"}

FORMATTING SYNTAX:
- Headings: ## for main sections, ### for subsections
- Text: **bold** for key terms and definitions, *italic* for emphasis
- Lists: - for unordered bullets, 1. 2. 3. for numbered lists
- Blockquotes: > for important notes or callouts
- Horizontal rules: --- to separate major sections
- Do NOT use emojis anywhere in the notes

MATHEMATICS (LaTeX):
Use LaTeX for all mathematical expressions. The app renders LaTeX using flutter_math_fork.

Inline math (within text): \$expression\$
  Examples: \$x^2 + y = z\$, \$E = mc^2\$, \$\\alpha + \\beta\$

Block math (centered, standalone): \$\$expression\$\$
  Examples:
  \$\$\\frac{a}{b}\$\$
  \$\$\\int_0^\\infty e^{-x} dx\$\$
  \$\$\\sum_{i=1}^{n} i = \\frac{n(n+1)}{2}\$\$

Common LaTeX commands:
- Fractions: \\frac{numerator}{denominator}
- Square roots: \\sqrt{x}, \\sqrt[n]{x}
- Exponents: x^2, x^{10}, e^{-x}
- Subscripts: x_1, x_{ij}
- Greek letters: \\alpha, \\beta, \\gamma, \\theta, \\pi, \\sigma
- Operators: \\sum, \\prod, \\int, \\lim
- Relations: \\leq, \\geq, \\neq, \\approx
- Arrows: \\rightarrow, \\Rightarrow, \\leftrightarrow
- Sets: \\in, \\subset, \\cup, \\cap

CODE: Use fenced blocks with language identifier
  ```python
  code here
  ```

STRUCTURE:
- Start with a brief overview paragraph
- Use clear section headings for each major topic
- Include definitions, explanations, and examples
- Summarize key points at the end when appropriate
- Target 500-2000 words with thorough coverage

JSON RULES: Escape quotes as \\" and newlines as \\n in the notes string.
''';

/// Prompt for generating flashcards from notes
const String _flashcardsFromNotesPrompt = '''
Create flashcards from the provided study notes.

OUTPUT: Return ONLY valid JSON (no markdown fences):

{"cards": [{"question": "Question text", "answer": "Answer text", "tags": ["tag1", "tag2"], "difficulty": "easy"}]}

RULES:
- One concept per card
- Clear questions (what, how, why, compare)
- Complete, concise answers
- Do NOT use emojis
- For math, use LaTeX: \$x^2\$ for inline, \$\$\\frac{a}{b}\$\$ for block
- Common LaTeX: \\frac{}{}, \\sqrt{}, \\sum, \\int, ^{}, _{}, Greek letters (\\alpha, \\beta, etc.)
- difficulty: exactly "easy", "medium", or "hard"
- tags: 2-4 lowercase keywords
- Generate 15-25 cards covering all major concepts
- Escape quotes as \\" in JSON strings
''';

/// Prompt for generating quiz from notes
const String _quizFromNotesPrompt = '''
Create a multiple-choice quiz from the provided study notes.

OUTPUT: Return ONLY valid JSON (no markdown fences):

{"questions": [{"question": "Question text", "options": ["A", "B", "C", "D"], "correctAnswer": 0, "explanation": "Why correct", "difficulty": "medium"}]}

RULES:
- Clear questions testing understanding
- Exactly 4 options per question
- correctAnswer: 0, 1, 2, or 3 (index of correct option)
- Plausible distractors (wrong answers)
- Brief, clear explanation of why the answer is correct
- Do NOT use emojis
- difficulty: exactly "easy", "medium", or "hard"
- For math, use LaTeX: \$x^2\$ for inline, \$\$\\frac{a}{b}\$\$ for block
- Generate 10-20 questions covering all topics
- Escape quotes as \\" in JSON strings
''';

class PromptService {
  late final GenerativeModel _model;

  PromptService() {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  // ==================== NOTES GENERATION ====================

  /// Generate notes from text content
  Future<String> generateNotesFromText(String text) async {
    final response = await _model.generateContent([
      Content.text('$_notesPrompt\n\nContent:\n$text'),
    ]);
    return response.text ?? '';
  }

  /// Generate notes from a PDF file (as bytes)
  Future<String> generateNotesFromPdf(Uint8List pdfBytes) async {
    final response = await _model.generateContent([
      Content.multi([
        TextPart(_notesPrompt),
        InlineDataPart('application/pdf', pdfBytes),
      ]),
    ]);
    return response.text ?? '';
  }

  /// Generate notes from an image (as bytes)
  Future<String> generateNotesFromImage(Uint8List imageBytes, String mimeType) async {
    final response = await _model.generateContent([
      Content.multi([
        TextPart(_notesPrompt),
        InlineDataPart(mimeType, imageBytes),
      ]),
    ]);
    return response.text ?? '';
  }

  /// Generate notes from a YouTube video URL
  Future<String> generateNotesFromYouTube(String youtubeUrl) async {
    try {
      final response = await _model.generateContent([
        Content.multi([
          TextPart(_notesPrompt),
          FileData('video/mp4', youtubeUrl),
        ]),
      ]);
      return response.text ?? '';
    } catch (e) {
      // Fallback: Ask Gemini to analyze the YouTube URL as text
      final fallbackPrompt = '''
$_notesPrompt

Please analyze this YouTube video and create study notes based on its content:
$youtubeUrl

If you cannot access the video directly, please indicate this in the notes field and create notes based on any information you can infer from the URL (video title, channel, etc.) or return a minimal response explaining the limitation.
''';
      final response = await _model.generateContent([Content.text(fallbackPrompt)]);
      return response.text ?? '';
    }
  }

  /// Generate notes from a generic URL
  Future<String> generateNotesFromUrl(String url) async {
    if (_isYouTubeUrl(url)) {
      return generateNotesFromYouTube(url);
    }
    return generateNotesFromText('URL: $url');
  }

  /// Generate notes from multiple files
  Future<String> generateNotesFromMultipleFiles(List<FileInput> files) async {
    final parts = <Part>[TextPart(_notesPrompt)];

    for (final file in files) {
      parts.add(InlineDataPart(file.mimeType, file.bytes));
    }

    final response = await _model.generateContent([Content.multi(parts)]);
    return response.text ?? '';
  }

  // ==================== FLASHCARDS FROM NOTES ====================

  /// Generate flashcards from notes content
  Future<String> generateFlashcardsFromNotes(String notesContent) async {
    final response = await _model.generateContent([
      Content.text('$_flashcardsFromNotesPrompt\n\nStudy Notes:\n$notesContent'),
    ]);
    return response.text ?? '';
  }

  // ==================== QUIZ FROM NOTES ====================

  /// Generate quiz from notes content
  Future<String> generateQuizFromNotes(String notesContent) async {
    final response = await _model.generateContent([
      Content.text('$_quizFromNotesPrompt\n\nStudy Notes:\n$notesContent'),
    ]);
    return response.text ?? '';
  }

  // ==================== LEGACY METHODS (for backward compatibility) ====================

  /// Generate raw JSON from text content (legacy - generates flashcards directly)
  Future<String> generateFromText(String text) async {
    return generateNotesFromText(text);
  }

  /// Generate raw JSON from a PDF file (legacy)
  Future<String> generateFromPdf(Uint8List pdfBytes) async {
    return generateNotesFromPdf(pdfBytes);
  }

  /// Generate raw JSON from an image (legacy)
  Future<String> generateFromImage(Uint8List imageBytes, String mimeType) async {
    return generateNotesFromImage(imageBytes, mimeType);
  }

  /// Generate raw JSON from a YouTube video URL (legacy)
  Future<String> generateFromYouTube(String youtubeUrl) async {
    return generateNotesFromYouTube(youtubeUrl);
  }

  /// Generate raw JSON from a generic URL (legacy)
  Future<String> generateFromUrl(String url) async {
    return generateNotesFromUrl(url);
  }

  /// Generate raw JSON from multiple files (legacy)
  Future<String> generateFromMultipleFiles(List<FileInput> files) async {
    return generateNotesFromMultipleFiles(files);
  }

  // ==================== UTILITIES ====================

  /// Check if a URL is a YouTube link
  bool _isYouTubeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('youtube-nocookie.com');
  }

  /// Public method to check YouTube URLs
  bool isYouTubeUrl(String url) => _isYouTubeUrl(url);
}

/// Helper class for file inputs
class FileInput {
  final Uint8List bytes;
  final String mimeType;
  final String? fileName;

  FileInput({
    required this.bytes,
    required this.mimeType,
    this.fileName,
  });

  /// Get mime type from file extension
  static String getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
