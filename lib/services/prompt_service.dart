import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

/// Prompt for generating notes from content
const String _notesPrompt = '''
You are an expert note-taker specializing in creating comprehensive, well-structured study notes from educational content.

TASK: Analyze the provided content (document, image, or video transcript) and create detailed study notes that capture all important information in an organized, learnable format.

NOTE-TAKING STRATEGY:

1. Structure: Organize notes with clear hierarchy using headings and subheadings. Group related concepts together logically.

2. Completeness: Capture all key concepts, definitions, facts, processes, examples, and applications. Include important details, but omit filler content and redundancy.

3. Clarity: Write in clear, concise language. Define technical terms. Use bullet points for lists and steps. Emphasize critical information.

4. Learning-Focused: Present information in a way that facilitates understanding and retention. Connect related ideas. Highlight cause-effect relationships. Include examples that illustrate concepts.

OUTPUT FORMAT:

Return ONLY valid JSON with this exact structure:

{
  "title": "Concise title describing the content topic",
  "subject": "Primary subject area (e.g., Biology, History, Mathematics, Computer Science)",
  "notes": "Complete markdown-formatted notes with headings, bullet points, and emphasis. Use ## for main sections, ### for subsections, **bold** for key terms, - for bullets, and numbered lists where appropriate."
}

NOTES FORMATTING RULES:

Use markdown syntax: ## for main topics, ### for subtopics, **bold** for important terms and concepts, - for bullet points, 1. 2. 3. for ordered lists or steps, > for important quotes or key takeaways, ` for code or formulas if present.

Structure guidelines: Start with a brief overview if the content has one. Organize by major topics and subtopics. Use parallel structure in lists. Keep paragraphs focused on single ideas. Include examples under relevant concepts.

Content guidelines: Define all technical terminology. Include numerical data, dates, and statistics. Capture step-by-step processes completely. Note relationships between concepts. Include context where it aids understanding.

CONTENT-SPECIFIC INSTRUCTIONS:

For documents (PDF/text): Extract information in the order presented unless reorganization improves clarity. Capture all headings and section structures. Include information from tables, charts, and figures. Note any formulas, equations, or special notation.

For images: Transcribe all visible text accurately. Describe diagrams with labels and relationships. Extract data from charts and graphs. Explain visual processes step-by-step. Note color coding or symbolic meanings.

For videos: Focus on teaching content, not meta-commentary. Organize by topics discussed, not chronologically. Capture definitions and explanations. Include examples and demonstrations. Note any recommended resources.

QUALITY STANDARDS:

Notes should be 500-2000 words depending on content richness. All major concepts must be covered. Information must be accurate and complete. Organization must be logical and clear. Formatting must enhance readability.

OUTPUT RULES:

Output ONLY the JSON object. No markdown code fences, no extra text. Use double quotes throughout. Escape special characters properly (quotes become \\", newlines become \\n). The notes field contains a single string with markdown formatting.

Now analyze the content and generate comprehensive study notes.
''';

/// Prompt for generating flashcards from notes
const String _flashcardsFromNotesPrompt = '''
You are an expert at creating effective flashcards from study notes that promote active recall and spaced repetition.

TASK: Convert the provided study notes into high-quality flashcards optimized for learning and retention.

FLASHCARD CREATION PRINCIPLES:

1. One Concept Per Card: Each flashcard tests a single, specific piece of knowledge.

2. Question Quality: Use clear, unambiguous questions. Avoid yes/no questions. Focus on understanding, not just memorization. Vary question types (what, how, why, when, compare, apply).

3. Answer Quality: Provide complete, self-contained answers. Include enough context to be meaningful. Keep answers concise but comprehensive.

4. Coverage: Create flashcards for all important concepts in the notes. Include definitions, processes, comparisons, applications, and examples. Distribute difficulty appropriately.

OUTPUT FORMAT:

Return ONLY valid JSON with this exact structure:

{
  "cards": [
    {
      "question": "Clear, specific question",
      "answer": "Complete, concise answer",
      "tags": ["tag1", "tag2", "tag3"],
      "difficulty": "easy, medium, or hard"
    }
  ]
}

FLASHCARD TYPES TO CREATE:

Definition cards: "What is [term]?" "Define [concept]."

Explanation cards: "Explain how [process] works." "What is the purpose of [concept]?"

Application cards: "How would you use [concept] in [context]?" "When should you apply [method]?"

Comparison cards: "What's the difference between [A] and [B]?" "Compare [concept A] and [concept B]."

Process cards: "What are the steps to [process]?" "Describe the procedure for [task]."

Example cards: "Give an example of [concept]." "What illustrates [principle]?"

Cause-effect cards: "What causes [phenomenon]?" "What is the result of [action]?"

FIELD SPECIFICATIONS:

question: 10-150 characters. Must be specific and unambiguous. Test one concept only.

answer: 30-300 characters. Must be complete and accurate. Include necessary context.

tags: 2-4 relevant keywords. Lowercase. Related to subject and specific topics.

difficulty: Exactly "easy", "medium", or "hard". Easy = basic recall, Medium = understanding/application, Hard = analysis/synthesis. Distribute as 40% easy, 40% medium, 20% hard.

QUANTITY GUIDELINES:

Generate 15-25 flashcards depending on notes length and complexity. Ensure comprehensive coverage of all major topics. Don't create redundant cards. Focus on testable, important information.

QUALITY RULES:

Every major concept from notes must have at least one card. Questions must be clear and answerable from the notes. Answers must be accurate and derived from the notes. Tags must reflect actual note content. Difficulty ratings must be appropriate.

OUTPUT RULES:

Output ONLY the JSON object. No markdown fences, no extra text. Use double quotes. Escape special characters. Difficulty must be exactly "easy", "medium", or "hard". Tags must be an array of strings.

Now convert the study notes into flashcards.
''';

/// Prompt for generating quiz from notes
const String _quizFromNotesPrompt = '''
You are an expert at creating effective practice quizzes that test comprehension and reinforce learning.

TASK: Convert the provided study notes into a practice quiz with multiple-choice questions that assess understanding of the material.

QUIZ DESIGN PRINCIPLES:

1. Test Understanding: Questions should assess comprehension, not just memorization. Include application, analysis, and comparison questions.

2. Quality Distractors: Wrong answers should be plausible but clearly incorrect. Use common misconceptions or partial truths. Avoid obviously wrong or silly options.

3. Clear Questions: Each question must be unambiguous and have one clearly correct answer. Avoid "all of the above" or "none of the above" unless necessary.

4. Comprehensive Coverage: Quiz should cover all major topics from the notes. Balance between different difficulty levels.

OUTPUT FORMAT:

Return ONLY valid JSON with this exact structure:

{
  "questions": [
    {
      "question": "Clear, specific question text",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": 0,
      "explanation": "Brief explanation of why the answer is correct",
      "difficulty": "easy, medium, or hard"
    }
  ]
}

QUESTION TYPES TO INCLUDE:

Recall questions: Test knowledge of definitions, facts, and key concepts.

Comprehension questions: Test understanding of explanations and processes.

Application questions: Test ability to use knowledge in scenarios.

Analysis questions: Test ability to break down concepts or compare/contrast.

Inference questions: Test ability to draw conclusions from information.

FIELD SPECIFICATIONS:

question: Clear, complete question (20-200 characters). Must be answerable from the notes.

options: Array of exactly 4 answer choices. Each 5-100 characters. One correct, three plausible distractors. Parallel structure and similar length.

correctAnswer: Index of correct option (0, 1, 2, or 3). 0 = first option, 1 = second, etc.

explanation: 30-150 characters. Briefly explain why the correct answer is right or what makes it the best choice. Reference key concept from notes.

difficulty: Exactly "easy", "medium", or "hard". Easy = straightforward recall, Medium = understanding/application, Hard = complex analysis. Distribute as 30% easy, 50% medium, 20% hard.

DISTRACTOR CREATION:

Make wrong answers believable and tempting. Use related but incorrect concepts. Include common errors or misconceptions. Ensure distractors are clearly wrong to someone who knows the material. Avoid obviously absurd or joke answers.

QUANTITY AND COVERAGE:

Generate 10-20 questions depending on notes length. Cover all major topics proportionally. Don't cluster too many questions on one topic. Mix difficulty levels throughout the quiz.

QUALITY STANDARDS:

Every question must be clear and unambiguous. Every question must have exactly one correct answer. Correct answers must be verifiable from the notes. Distractors must be plausible. Explanations must be helpful and accurate. Difficulty ratings must be appropriate.

OUTPUT RULES:

Output ONLY the JSON object. No markdown fences, no extra text. Use double quotes throughout. Escape special characters properly. correctAnswer must be 0, 1, 2, or 3. Difficulty must be exactly "easy", "medium", or "hard". Options must be an array of exactly 4 strings.

Now convert the study notes into a practice quiz.
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
