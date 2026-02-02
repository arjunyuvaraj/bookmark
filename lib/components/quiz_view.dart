import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmark/models/quiz_question.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;

const double _cardRadius = 8.0;
const double _optionSpacing = 8.0;

class QuizView extends StatefulWidget {
  final List<QuizQuestion> questions;
  final Future<void> Function(int score, int totalQuestions)? onCompleted;

  const QuizView({super.key, required this.questions, this.onCompleted});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _hasAnswered = false;
  int _correctCount = 0;
  bool _quizComplete = false;

  QuizQuestion get _question => widget.questions[_currentIndex];

  // ---------------- Logic ----------------

  void _selectAnswer(int index) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = index;
      _hasAnswered = true;

      if (index == _question.correctIndex) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    final isLast = _currentIndex == widget.questions.length - 1;

    setState(() {
      if (isLast) {
        _quizComplete = true;
      } else {
        _currentIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      }
    });

    if (isLast && widget.onCompleted != null) {
      widget.onCompleted!(_correctCount, widget.questions.length);
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

  // ---------------- UI ----------------

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        _buildProgress(),
        const SizedBox(height: 24),
        _buildQuestionCard(),
        const SizedBox(height: 24),
        _buildOptions(),
        if (_hasAnswered) _buildNextButton(),
      ],
    );
  }

  // ---------------- Sections ----------------

  Widget _buildHeader() {
    return Padding(
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
            style: TextStyle(color: colors.accentBlue, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return LinearProgressIndicator(
      value: (_currentIndex + 1) / widget.questions.length,
      backgroundColor: colors.surface.withOpacity(0.3),
      color: colors.accentBlue,
      minHeight: 6,
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: colors.outline),
      ),
      child: Text(
        _question.question,
        style: GoogleFonts.inter(
          color: colors.white,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Expanded(
      child: ListView.separated(
        itemCount: _question.options.length,
        separatorBuilder: (_, __) => const SizedBox(height: _optionSpacing),
        itemBuilder: (context, index) {
          return _OptionTile(
            label: String.fromCharCode(65 + index),
            text: _question.options[index],
            selected: _selectedAnswer == index,
            correct: index == _question.correctIndex,
            showResult: _hasAnswered,
            onTap: () => _selectAnswer(index),
          );
        },
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentIndex == widget.questions.length - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton(
        onPressed: _nextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentBlue,
          foregroundColor: colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
        ),
        child: Text(
          isLast ? 'See Results' : 'Next Question',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  // ---------------- Results ----------------

  Widget _buildResultsView() {
    final percentage = (_correctCount / widget.questions.length * 100).round();
    final success = percentage >= 70;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildScoreBadge(percentage, success),
          const SizedBox(height: 24),
          Text(
            'Quiz Complete!',
            style: GoogleFonts.inter(
              color: colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You got $_correctCount out of ${widget.questions.length} correct',
            style: TextStyle(color: colors.secondary, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _restartQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentBlue,
              foregroundColor: colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_cardRadius),
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

  Widget _buildScoreBadge(int percentage, bool success) {
    final color = success ? Colors.green : Colors.orange;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: color),
      ),
      child: Center(
        child: Text(
          '$percentage%',
          style: GoogleFonts.inter(
            color: colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// ---------------- Option Tile ----------------

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final bool correct;
  final bool showResult;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.correct,
    required this.showResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorsData = _resolveColors();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorsData.background,
          borderRadius: BorderRadius.circular(_cardRadius),
          border: Border.all(color: colorsData.border),
        ),
        child: Row(
          children: [
            _buildBadge(colorsData.border),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: colors.white, fontSize: 14),
              ),
            ),
            if (showResult && correct)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (showResult && selected && !correct)
              const Icon(Icons.cancel, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }

  _OptionColors _resolveColors() {
    if (!showResult && selected) {
      return _OptionColors(
        background: colors.accentBlue.withOpacity(0.15),
        border: colors.accentBlue,
      );
    }

    if (showResult && correct) {
      return _OptionColors(
        background: Colors.green.withOpacity(0.15),
        border: Colors.green,
      );
    }

    if (showResult && selected && !correct) {
      return _OptionColors(
        background: Colors.red.withOpacity(0.15),
        border: Colors.red,
      );
    }

    return _OptionColors(background: colors.surface, border: colors.outline);
  }

  Widget _buildBadge(Color borderColor) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_cardRadius),
        color: selected ? borderColor : colors.surface,
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.white : borderColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _OptionColors {
  final Color background;
  final Color border;

  const _OptionColors({required this.background, required this.border});
}
