import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';

/// The comprehensive prompt for generating flashcards from any content type
const String _flashcardPrompt = '''
You are an expert educational content analyzer and flashcard creator. Your task is to analyze the provided content (PDF, text document, image, or YouTube video transcript) and generate high-quality flashcards that will help students learn and retain the key concepts.

CONTENT ANALYSIS PROCESS:

1. Identify Content Type: Determine if the content is from a document (PDF/text), visual material (image/diagram), or video transcript (YouTube). Adapt your analysis accordingly.

2. For Documents (PDF/TXT): Extract main concepts and topics, key definitions and terminology, important facts and figures, processes and procedures, relationships between concepts, and practical examples.

3. For Images: Identify all text content, labels, and captions. Analyze diagrams, charts, graphs, and tables. Note visual elements like arrows, color coding, and symbols. Recognize formulas, equations, and mathematical notation. Identify processes, cycles, or sequences shown visually.

4. For Video Transcripts (YouTube): Focus on key teaching points and explanations. Extract important definitions and concepts. Identify examples and demonstrations mentioned. Note any step-by-step processes or tutorials. Capture important facts, statistics, or research mentioned.

5. Create Effective Flashcards: Follow these principles for all content types: one concept per card focusing on a single clear idea, clear and concise questions that are unambiguous and direct, complete answers that are comprehensive but concise, progressive difficulty with a mix of basic recall and higher-level understanding, active recall focus by framing questions to promote active learning, avoid simple yes/no questions and use open-ended questions instead.

FLASHCARD TYPES TO CREATE:

For all content types, include a variety of these question types: Definition cards asking "What is [term]?" or "Define [concept]", concept explanation cards asking "Explain how [process] works" or "What is the purpose of [concept]?", application cards asking "How would you apply [concept] in [scenario]?" or "When would you use [method]?", comparison cards asking "What is the difference between [A] and [B]?" or "Compare [concept A] and [concept B]", example cards asking "Give an example of [concept]" or "What is a real-world application of [principle]?", process cards asking "What are the steps in [process]?" or "Describe the procedure for [task]".

For images specifically, also include: Visual interpretation cards asking "What does [component] represent in the diagram?", relationship cards asking "How do [elements] connect or interact?", data interpretation cards for charts and graphs asking about trends and patterns.

For video content specifically, also include: Teaching point cards capturing the main lessons or takeaways, demonstration cards about examples or case studies shown, timeline cards for historical or sequential content.

OUTPUT FORMAT REQUIREMENTS:

You MUST respond with ONLY valid JSON in the exact format shown below. Do not include any markdown formatting, code blocks, backticks, or any additional text before or after the JSON. The JSON must be valid and parseable.

{
  "title": "Brief descriptive title for this flashcard set",
  "description": "One or two sentence summary of what this content covers",
  "fileType": "video, pdf, csv, or none",
  "cards": [
    {
      "question": "Clear, concise question text",
      "answer": "Comprehensive answer text",
      "tags": ["tag1", "tag2", "tag3"],
      "difficulty": "easy, medium, or hard"
    }
  ]
}

FIELD SPECIFICATIONS:

title: A clear, concise title that describes the subject matter (20-100 characters). Should capture the main topic or subject area.

description: A brief summary explaining what the content covers and what students will learn (50-200 characters). Should give context about the material.

fileType: Must be exactly one of these values: "video" for YouTube content, "pdf" for PDF documents, "csv" for spreadsheet data, "none" for plain text or images. Use "none" if the type is ambiguous.

cards: An array containing flashcard objects. Generate 10-25 flashcards depending on content richness. Each flashcard must have:
  - question: The front of the card, what students see first (typically 10-200 characters). Must be clear, specific, and unambiguous.
  - answer: The back of the card, the information to learn (typically 30-500 characters). Should be comprehensive but concise.
  - tags: An array of 2-5 relevant keywords for categorization and searching. Use lowercase. Examples: ["biology", "photosynthesis", "plants"], ["history", "wwii", "europe"], ["math", "algebra", "equations"]
  - difficulty: Must be exactly "easy", "medium", or "hard". Distribute across difficulty levels with roughly 40% easy, 40% medium, 20% hard.

QUALITY GUIDELINES:

Content Coverage: Generate 10-15 flashcards for shorter content, 15-20 for medium content, 20-25 for comprehensive content. Ensure all major topics and concepts are covered. Include foundational concepts first, then build to more complex ideas.

Question Quality: Keep questions focused and specific. Avoid vague or overly broad questions. Use clear, simple language. Frame questions to test understanding, not just memorization. Vary question formats across the set.

Answer Quality: Provide complete, accurate answers. Include relevant context when needed. Use clear explanations for complex concepts. Keep answers concise but informative. Define technical terms when using them.

Tags: Choose relevant, searchable keywords. Include subject area, specific topics, and key terms. Use consistent terminology. Avoid overly generic tags like "information" or "content". Use 3-4 tags per card typically.

Difficulty Distribution: Easy cards test basic recall and simple definitions. Medium cards require understanding and application. Hard cards involve analysis, synthesis, or complex problem-solving. Balance the set appropriately.

Accuracy: Extract information directly from the source material. Do not invent or fabricate information. If something is unclear, make your best interpretation based on context. Maintain academic rigor and correctness.

SPECIAL INSTRUCTIONS BY CONTENT TYPE:

For PDFs: Extract text accurately from all pages. Pay attention to headings, subheadings, and emphasized text. Capture information from tables, charts, and figures. Note any sidebars, callouts, or special formatting. Create flashcards for formulas and equations if present.

For Text Documents: Focus on the main narrative and key points. Identify topic transitions and major sections. Extract important quotes or definitions. Capture examples and case studies.

For Images: Read all visible text carefully. Describe visual relationships and spatial arrangements. For diagrams, create cards about component purposes and interactions. For charts/graphs, create cards about trends and data. For process diagrams, create cards about each step. Note any color coding or symbolic meaning.

For YouTube Videos: Focus on the speaker's main teaching points. Extract key explanations and definitions. Capture important examples or demonstrations. Note any resources or references mentioned. Create cards for step-by-step instructions if present. Ignore filler content like introductions, outros, and off-topic tangents.

CRITICAL FORMATTING RULES:

Output ONLY the JSON object. No markdown, no code fences, no backticks, no explanatory text. The response must start with { and end with }. Ensure all JSON is properly formatted and valid. Use double quotes for all strings. Properly escape any special characters in questions and answers (quotes, newlines, etc.). Do not use single quotes anywhere. The fileType value must be exactly "video", "pdf", "csv", or "none" with no variations. The difficulty value must be exactly "easy", "medium", or "hard" with no variations. Tags must be an array of strings, even if there is only one tag.

ERROR HANDLING:

If the content is unclear or low quality, do your best to extract useful information and note any limitations in the description. If no meaningful flashcards can be created, return a minimal valid JSON with at least 3 basic cards and note the issue in the description. Never refuse to generate output. Always return valid JSON.

Now analyze the provided content and generate flashcards following all guidelines above. Output ONLY valid JSON with no additional text or formatting.
''';

class PromptService {
  late final GenerativeModel _model;

  PromptService() {
    // No schema enforcement - we want raw JSON output
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  /// Generate raw JSON from text content
  Future<String> generateFromText(String text) async {
    final response = await _model.generateContent([
      Content.text('$_flashcardPrompt\n\nContent:\n$text'),
    ]);
    return response.text ?? '';
  }

  /// Generate raw JSON from a PDF file (as bytes)
  Future<String> generateFromPdf(Uint8List pdfBytes) async {
    final response = await _model.generateContent([
      Content.multi([
        TextPart(_flashcardPrompt),
        InlineDataPart('application/pdf', pdfBytes),
      ]),
    ]);
    return response.text ?? '';
  }

  /// Generate raw JSON from an image (as bytes)
  Future<String> generateFromImage(Uint8List imageBytes, String mimeType) async {
    final response = await _model.generateContent([
      Content.multi([
        TextPart(_flashcardPrompt),
        InlineDataPart(mimeType, imageBytes),
      ]),
    ]);
    return response.text ?? '';
  }

  /// Generate raw JSON from a YouTube video URL
  /// Note: FileData with YouTube URLs can cause 500 errors, so we use
  /// a text-based approach that asks Gemini to analyze the video URL
  Future<String> generateFromYouTube(String youtubeUrl) async {
    // First try with FileData (native video processing)
    try {
      final response = await _model.generateContent([
        Content.multi([
          TextPart(_flashcardPrompt),
          FileData('video/mp4', youtubeUrl),
        ]),
      ]);
      return response.text ?? '';
    } catch (e) {
      // Fallback: Ask Gemini to analyze the YouTube URL as text
      // Gemini can often access and analyze YouTube content this way
      final fallbackPrompt = '''
$_flashcardPrompt

Please analyze this YouTube video and create flashcards based on its content:
$youtubeUrl

If you cannot access the video directly, please indicate this in the description field and create flashcards based on any information you can infer from the URL (video title, channel, etc.) or return a minimal response explaining the limitation.
''';
      final response = await _model.generateContent([Content.text(fallbackPrompt)]);
      return response.text ?? '';
    }
  }

  /// Generate raw JSON from a generic URL
  Future<String> generateFromUrl(String url) async {
    if (_isYouTubeUrl(url)) {
      return generateFromYouTube(url);
    }
    // For non-YouTube URLs, include as text
    return generateFromText('URL: $url');
  }

  /// Generate raw JSON from multiple files
  Future<String> generateFromMultipleFiles(List<FileInput> files) async {
    final parts = <Part>[TextPart(_flashcardPrompt)];

    for (final file in files) {
      parts.add(InlineDataPart(file.mimeType, file.bytes));
    }

    final response = await _model.generateContent([Content.multi(parts)]);
    return response.text ?? '';
  }

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
