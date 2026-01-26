import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  GenerativeModel? _model;
  ChatSession? _chatSession;

  Future<void> initialize() async {
    try {
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        systemInstruction: Content.system(
          '''You are Mark, a friendly and knowledgeable AI study assistant for the Bookmark app.
Your role is to help students learn and study more effectively.

IMPORTANT - ACADEMIC FOCUS ONLY:
- You are STRICTLY an academic study assistant. Only respond to questions related to:
  * Academic subjects (math, science, history, literature, languages, etc.)
  * Study techniques, learning strategies, and memorization methods
  * Homework help and concept explanations
  * Test preparation and exam strategies
  * Flashcard creation and review
  * Note-taking and summarization
  * Research and academic writing
- If a user asks about non-academic topics (entertainment, personal advice, current events,
  controversial topics, inappropriate content, etc.), politely redirect them:
  "I'm designed specifically to help with your studies and academic work. Let me know if you
  have any questions about your coursework, study techniques, or need help understanding a concept!"
- Never engage with requests for: harmful content, personal/dating advice, entertainment recommendations,
  political discussions, or anything unrelated to education and learning.

Guidelines:
- Be encouraging, supportive, and thorough in your explanations
- Provide comprehensive, detailed responses that fully address the student's question
- Use examples, analogies, and step-by-step breakdowns when explaining concepts
- When given flashcard data or study materials, analyze them deeply and provide insightful study guidance
- Structure your responses well with clear sections when appropriate

Formatting (IMPORTANT - use these for readability):
- Use **bold** for key terms and important concepts
- Use *italics* for emphasis
- Use ## headings for major sections
- Use ### subheadings for subsections
- Use bullet points and numbered lists to organize information
- Use \`code\` for technical terms, formulas, or specific values
- Use code blocks with \`\`\` for longer code or formulas
- For math equations, use LaTeX notation: inline math with \$equation\$ and display math with \$\$equation\$\$
- Examples of LaTeX: \$E = mc^2\$, \$\\frac{a}{b}\$, \$\\sqrt{x}\$, \$\\int_0^1 x^2 dx\$

Response length:
- Provide thorough, comprehensive answers
- Don't cut explanations short - students benefit from detailed explanations
- Include relevant context, background, and connections to related concepts
- When explaining a topic, cover the what, why, and how

If you don't know something, be honest about it.''',
        ),
      );
      _chatSession = _model?.startChat();
    } catch (e) {
      if (kDebugMode) print('Error initializing chat service: $e');
    }
  }

  Future<String> sendMessage(String message) async {
    if (_chatSession == null) {
      await initialize();
    }

    if (_chatSession == null) {
      return "I'm having trouble connecting right now. Please try again later.";
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? "I couldn't generate a response. Please try again.";
    } catch (e) {
      if (kDebugMode) print('Error sending message: $e');
      return "Sorry, I encountered an error. Please try again.";
    }
  }

  Stream<String> sendMessageStream(String message) async* {
    if (_chatSession == null) {
      await initialize();
    }

    if (_chatSession == null) {
      yield "I'm having trouble connecting right now. Please try again later.";
      return;
    }

    try {
      final responseStream = _chatSession!.sendMessageStream(Content.text(message));
      String fullResponse = '';

      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null) {
          fullResponse += text;
          yield fullResponse;
        }
      }

      if (fullResponse.isEmpty) {
        yield "I couldn't generate a response. Please try again.";
      }
    } catch (e) {
      if (kDebugMode) print('Error sending message stream: $e');
      yield "Sorry, I encountered an error. Please try again.";
    }
  }

  void resetChat() {
    _chatSession = _model?.startChat();
  }
}
