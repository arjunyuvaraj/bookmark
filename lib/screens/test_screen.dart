import 'dart:convert';
import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/services/prompt_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestScreen extends StatefulWidget {
  final SetModel set;

  const TestScreen({super.key, required this.set});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final PromptService _promptService = PromptService();

  bool _isGenerating = false;
  bool _testGenerated = false;
  int _currentQuestion = 0;
  int _score = 0;
  bool _showResults = false;

  List<TestQuestion> _questions = [];
  Map<int, String> _userAnswers = {};

  @override
  void initState() {
    super.initState();
    _generateTest();
    _incrementSessions();
  }

  Future<void> _incrementSessions() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || widget.set.id == null) return;

    final setService = FlashcardSetService();
    await setService.incrementSessions(userId, widget.set.id!);
  }

  Future<void> _generateTest() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Create a prompt to generate test questions
      final cardsJson = widget.set.cards
          .map((c) => {'question': c.question, 'answer': c.answer})
          .toList();

      final prompt =
          '''
Generate a multiple choice test based on these flashcards. Create 10 questions with 4 options each (A, B, C, D).

Flashcards:
${jsonEncode(cardsJson)}

Return ONLY valid JSON in this exact format:
{
  "questions": [
    {
      "question": "Question text here",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctAnswer": 0
    }
  ]
}

The correctAnswer should be the index (0-3) of the correct option. Make questions challenging but fair.
''';

      final response = await _promptService.generateFromText(prompt);

      // Parse the response
      String cleanJson = response.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final data = jsonDecode(cleanJson);
      final questions = (data['questions'] as List)
          .map(
            (q) => TestQuestion(
              question: q['question'],
              options: List<String>.from(q['options']),
              correctAnswer: q['correctAnswer'],
            ),
          )
          .toList();

      setState(() {
        _questions = questions;
        _testGenerated = true;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate test: $e')));
      }
    }
  }

  void _selectAnswer(int optionIndex) {
    setState(() {
      _userAnswers[_currentQuestion] = optionIndex.toString();
    });
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
      });
    } else {
      _calculateScore();
    }
  }

  void _previousQuestion() {
    if (_currentQuestion > 0) {
      setState(() {
        _currentQuestion--;
      });
    }
  }

  void _calculateScore() {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      final userAnswer = _userAnswers[i];
      if (userAnswer != null &&
          int.parse(userAnswer) == _questions[i].correctAnswer) {
        correct++;
      }
    }
    setState(() {
      _score = correct;
      _showResults = true;
    });
  }

  void _retakeTest() {
    setState(() {
      _currentQuestion = 0;
      _score = 0;
      _showResults = false;
      _userAnswers.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Test: ${widget.set.title}',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: colors.surface.withAlpha(230),
        elevation: 0,
      ),
      body: _isGenerating
          ? _buildLoading(context)
          : _showResults
          ? _buildResults(context)
          : _buildTest(context),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generating test questions...',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTest(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final question = _questions[_currentQuestion];
    final selectedAnswer = _userAnswers[_currentQuestion];

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestion + 1} of ${_questions.length}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colors.secondary,
                    ),
                  ),
                  Text(
                    '${_userAnswers.length}/${_questions.length} answered',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentQuestion + 1) / _questions.length,
                  backgroundColor: colors.outline.withAlpha(77),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline.withAlpha(128)),
                  ),
                  child: Text(
                    question.question,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Options
                ...List.generate(question.options.length, (index) {
                  final isSelected = selectedAnswer == index.toString();
                  final optionLetter = String.fromCharCode(
                    65 + index,
                  ); // A, B, C, D

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectAnswer(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary.withAlpha(26)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : colors.outline.withAlpha(128),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primary
                                    : colors.outline.withAlpha(51),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  optionLetter,
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? colors.onPrimary
                                        : colors.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: colors.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Navigation
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surface.withAlpha(230),
            border: Border(
              top: BorderSide(color: colors.outline.withAlpha(128)),
            ),
          ),
          child: Row(
            children: [
              if (_currentQuestion > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousQuestion,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: colors.outline.withAlpha(128)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Previous',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              if (_currentQuestion > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: selectedAnswer != null ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _currentQuestion == _questions.length - 1
                        ? 'Finish Test'
                        : 'Next Question',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percentage = (_score / _questions.length * 100).round();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$percentage%',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Test Complete!',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You got $_score out of ${_questions.length} correct',
              style: GoogleFonts.inter(fontSize: 16, color: colors.secondary),
            ),
            const SizedBox(height: 48),

            // Review incorrect answers
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outline.withAlpha(128)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_questions.length, (index) {
                    final q = _questions[index];
                    final userAnswer = _userAnswers[index];
                    final isCorrect =
                        userAnswer != null &&
                        int.parse(userAnswer) == q.correctAnswer;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Q${index + 1}: ${q.question.substring(0, q.question.length > 40 ? 40 : q.question.length)}${q.question.length > 40 ? '...' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: colors.outline.withAlpha(128)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Back to Set',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _retakeTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Retake Test',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
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

class TestQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;

  TestQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}
