import 'dart:convert';
import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/services/prompt_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _showQuestionNavigator = false;

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

  void _jumpToQuestion(int index) {
    setState(() {
      _currentQuestion = index;
      _showQuestionNavigator = false;
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

  int get _unansweredCount {
    return _questions.length - _userAnswers.length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent && !_showResults && _testGenerated) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _nextQuestion();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _previousQuestion();
          } else if (event.logicalKey == LogicalKeyboardKey.digit1 ||
              event.logicalKey == LogicalKeyboardKey.keyA) {
            _selectAnswer(0);
          } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
              event.logicalKey == LogicalKeyboardKey.keyB) {
            _selectAnswer(1);
          } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
              event.logicalKey == LogicalKeyboardKey.keyC) {
            _selectAnswer(2);
          } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
              event.logicalKey == LogicalKeyboardKey.keyD) {
            _selectAnswer(3);
          }
        }
      },
      child: Scaffold(
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
          actions: [
            if (_testGenerated && !_showResults)
              IconButton(
                icon: const Icon(Icons.grid_view_rounded),
                tooltip: 'Question Navigator',
                onPressed: () {
                  setState(() {
                    _showQuestionNavigator = !_showQuestionNavigator;
                  });
                },
              ),
          ],
        ),
        body: Stack(
          children: [
            _isGenerating
                ? _buildLoading(context)
                : _showResults
                ? _buildResults(context)
                : _buildTest(context),
            if (_showQuestionNavigator)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showQuestionNavigator = false;
                  });
                },
                child: Container(color: Colors.black.withAlpha(128)),
              ),
            if (_showQuestionNavigator) _buildQuestionNavigator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionNavigator(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        decoration: BoxDecoration(
          color: isDark ? colors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withAlpha(128)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question Navigator',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showQuestionNavigator = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            Divider(color: colors.outline.withAlpha(77), height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final isAnswered = _userAnswers.containsKey(index);
                  final isCurrent = index == _currentQuestion;

                  return InkWell(
                    onTap: () => _jumpToQuestion(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? colors.primary
                            : isAnswered
                            ? colors.primary.withAlpha(26)
                            : colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCurrent
                              ? colors.primary
                              : isAnswered
                              ? colors.primary.withAlpha(128)
                              : colors.outline.withAlpha(128),
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isCurrent
                                ? colors.onPrimary
                                : isAnswered
                                ? colors.primary
                                : colors.onSurface.withAlpha(153),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(color: colors.outline.withAlpha(77), height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildLegendItem(context, colors.primary, 'Current'),
                  const SizedBox(width: 16),
                  _buildLegendItem(
                    context,
                    colors.primary.withAlpha(26),
                    'Answered',
                  ),
                  const SizedBox(width: 16),
                  _buildLegendItem(
                    context,
                    colors.surface,
                    'Not Answered',
                    borderColor: colors.outline.withAlpha(128),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    Color color,
    String label, {
    Color? borderColor,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: colors.secondary),
        ),
      ],
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
        // Progress bar with summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface.withAlpha(128),
            border: Border(
              bottom: BorderSide(color: colors.outline.withAlpha(77)),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestion + 1} of ${_questions.length}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _unansweredCount == 0
                          ? Colors.green.withAlpha(26)
                          : colors.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_userAnswers.length}/${_questions.length} answered',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _unansweredCount == 0
                            ? Colors.green[700]
                            : colors.primary,
                      ),
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

                // Keyboard hint
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withAlpha(128),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.outline.withAlpha(77)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_outlined,
                        size: 16,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Press 1-4 or A-D to select',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Options
                ...List.generate(question.options.length, (index) {
                  final isSelected = selectedAnswer == index.toString();
                  final optionLetter = String.fromCharCode(65 + index);

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percentage = (_score / _questions.length * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
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

          // Detailed Review
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? colors.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outline.withAlpha(128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: colors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Detailed Review',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ...List.generate(_questions.length, (index) {
                  final q = _questions[index];
                  final userAnswer = _userAnswers[index];
                  final isCorrect =
                      userAnswer != null &&
                      int.parse(userAnswer) == q.correctAnswer;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.withAlpha(13)
                          : Colors.red.withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green.withAlpha(77)
                            : Colors.red.withAlpha(77),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Colors.green.withAlpha(26)
                                    : Colors.red.withAlpha(26),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCorrect ? Icons.check : Icons.close,
                                color: isCorrect
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Question ${index + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          q.question,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colors.onSurface,
                            height: 1.4,
                          ),
                        ),
                        if (!isCorrect) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Correct: ${q.options[q.correctAnswer]}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Set'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  side: BorderSide(color: colors.outline.withAlpha(128)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _retakeTest,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retake Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
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
