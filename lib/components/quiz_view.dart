import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmark/models/quiz_question.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;

class QuizView extends StatefulWidget {
  final List<QuizQuestion> questions;

  const QuizView({super.key, required this.questions});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _hasAnswered = false;
  int _correctCount = 0;
  bool _quizComplete = false;

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = index;
      _hasAnswered = true;
      if (index == widget.questions[_currentIndex].correctIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
    } else {
      setState(() {
        _quizComplete = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentIndex = 0;
      _selectedAnswer = null;
      _hasAnswered = false;
      _correctCount = 0;
      _quizComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Center(
        child: Text(
          'No quiz questions available',
          style: TextStyle(color: colors.secondary),
        ),
      );
    }

    if (_quizComplete) {
      return _buildResultsView();
    }

    final question = widget.questions[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of ${widget.questions.length}',
                style: TextStyle(color: colors.secondary, fontSize: 14),
              ),
              Text(
                'Score: $_correctCount',
                style: TextStyle(color: colors.primaryBlue, fontSize: 14),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: (_currentIndex + 1) / widget.questions.length,
          backgroundColor: colors.inputBackground,
          color: colors.primaryBlue,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            question.question,
            style: GoogleFonts.instrumentSerif(
              color: colors.white,
              fontSize: 18,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: question.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final isSelected = _selectedAnswer == index;
              final isCorrect = index == question.correctIndex;
              final showResult = _hasAnswered;

              Color backgroundColor = colors.inputBackground;
              Color borderColor = colors.inputBorder;

              if (showResult) {
                if (isCorrect) {
                  backgroundColor = Colors.green.withValues(alpha: 0.2);
                  borderColor = Colors.green;
                } else if (isSelected && !isCorrect) {
                  backgroundColor = Colors.red.withValues(alpha: 0.2);
                  borderColor = Colors.red;
                }
              } else if (isSelected) {
                backgroundColor = colors.primaryBlue.withValues(alpha: 0.2);
                borderColor = colors.primaryBlue;
              }

              return GestureDetector(
                onTap: () => _selectAnswer(index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? borderColor
                              : colors.inputBackground,
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: isSelected ? colors.white : borderColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.options[index],
                          style: TextStyle(
                            color: colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (showResult && isCorrect)
                        const Icon(Icons.check_circle, color: Colors.green),
                      if (showResult && isSelected && !isCorrect)
                        const Icon(Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_hasAnswered)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryBlue,
                foregroundColor: colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentIndex < widget.questions.length - 1
                    ? 'Next Question'
                    : 'See Results',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsView() {
    final percentage = (_correctCount / widget.questions.length * 100).round();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: percentage >= 70
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              border: Border.all(
                color: percentage >= 70 ? Colors.green : Colors.orange,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                '$percentage%',
                style: GoogleFonts.instrumentSerif(
                  color: colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Quiz Complete!',
            style: GoogleFonts.instrumentSerif(
              color: colors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You got $_correctCount out of ${widget.questions.length} correct',
            style: TextStyle(color: colors.secondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _restartQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryBlue,
              foregroundColor: colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
