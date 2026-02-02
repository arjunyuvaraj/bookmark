import 'dart:convert';
import 'package:bookmark/components/quiz_view.dart';
import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/models/quiz_question.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/services/prompt_service.dart';
import 'package:bookmark/services/user_stats_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TestScreen extends StatefulWidget {
  final SetModel set;

  const TestScreen({super.key, required this.set});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final PromptService _promptService = PromptService();
  final UserStatsService _statsService = UserStatsService();
  late final FocusNode _focusNode;

  bool _isGenerating = false;
  bool _generationFailed = false;
  List<QuizQuestion> _questions = [];

  String? _rawAiResponse;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..requestFocus();
    _generateTest();
    _incrementSessions();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _incrementSessions() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || widget.set.id == null) return;
    await FlashcardSetService().incrementSessions(userId, widget.set.id!);
  }

  Future<void> _generateTest() async {
    if (!mounted) return;
    setState(() {
      _isGenerating = true;
      _generationFailed = false;
      _rawAiResponse = null;
      _parseError = null;
      _questions.clear();
    });

    try {
      final notesBuffer = StringBuffer();
      for (final c in widget.set.cards) {
        notesBuffer.writeln('• ${c.question}: ${c.answer}');
      }

      final response = await _promptService.generateQuizFromNotes(
        notesBuffer.toString(),
      );

      _rawAiResponse = response;
      final decoded = jsonDecode(_cleanJson(response));
      final questionsJson = decoded['questions'] as List<dynamic>?;

      if (questionsJson == null) throw Exception('Missing "questions"');

      final questions = questionsJson
          .map((q) => QuizQuestion.fromJson(q))
          .toList();

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _isGenerating = false;
      });
    } catch (e, stack) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _generationFailed = true;
        _parseError = '$e\n\n$stack';
      });
    }
  }

  String _cleanJson(String input) {
    return input
        .replaceAll(RegExp(r'^```json'), '')
        .replaceAll(RegExp(r'^```'), '')
        .replaceAll(RegExp(r'```$'), '')
        .trim();
  }

  Future<void> _onQuizCompleted(int score, int totalQuestions) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || widget.set.id == null) return;
    await _statsService.recordQuizCompleted(
      userId: userId,
      setId: widget.set.id!,
      setTitle: widget.set.title,
      score: score,
      totalQuestions: totalQuestions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          title: Text(
            'Test',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isGenerating) return _buildLoading();
    if (_generationFailed) return _buildError();
    if (_questions.isEmpty)
      return const Center(child: Text('No quiz questions generated.'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: QuizView(questions: _questions, onCompleted: _onQuizCompleted),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Generating quiz…',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to generate quiz',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          if (_parseError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SelectableText(
                _parseError!,
                style: GoogleFonts.jetBrainsMono(fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _generateTest, child: const Text('Retry')),
        ],
      ),
    );
  }
}
