import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bookmark/models/flashcard.dart';
import 'package:bookmark/theme/color_scheme.dart' as colors;

// Notion-style radius
const double _cardRadius = 8.0;

class FlashcardView extends StatefulWidget {
  final List<Flashcard> flashcards;

  const FlashcardView({super.key, required this.flashcards});

  @override
  State<FlashcardView> createState() => _FlashcardViewState();
}

class _FlashcardViewState extends State<FlashcardView> {
  int _currentIndex = 0;
  bool _showAnswer = false;

  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showAnswer = false;
      });
    }
  }

  void _flipCard() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return Center(
        child: Text(
          'No flashcards available',
          style: TextStyle(color: colors.secondary),
        ),
      );
    }

    final card = widget.flashcards[_currentIndex];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Card ${_currentIndex + 1} of ${widget.flashcards.length}',
            style: TextStyle(color: colors.secondary, fontSize: 14),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _flipCard,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                final rotate = Tween(begin: pi, end: 0.0).animate(animation);
                return AnimatedBuilder(
                  animation: rotate,
                  builder: (context, child) {
                    final isBack = rotate.value < pi / 2;
                    return Transform(
                      transform: Matrix4.rotationY(isBack ? 0 : pi),
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                  child: child,
                );
              },
              child: _FlashcardTile(
                key: ValueKey(_showAnswer),
                text: _showAnswer ? card.back : card.front,
                isAnswer: _showAnswer,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap card to flip',
          style: TextStyle(color: colors.secondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _currentIndex > 0 ? _previousCard : null,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: _currentIndex > 0 ? colors.white : colors.secondary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_cardRadius),
                  side: BorderSide(color: colors.outline),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              onPressed:
                  _currentIndex < widget.flashcards.length - 1 ? _nextCard : null,
              icon: Icon(
                Icons.arrow_forward_rounded,
                color: _currentIndex < widget.flashcards.length - 1
                    ? colors.white
                    : colors.secondary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_cardRadius),
                  side: BorderSide(color: colors.outline),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  final String text;
  final bool isAnswer;

  const _FlashcardTile({
    super.key,
    required this.text,
    required this.isAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isAnswer ? colors.accentBlue.withValues(alpha: 0.1) : colors.surface,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: isAnswer ? colors.accentBlue : colors.outline,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isAnswer ? 'Answer' : 'Question',
            style: TextStyle(
              color: isAnswer ? colors.accentBlue : colors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: GoogleFonts.inter(
              color: colors.white,
              fontSize: 18,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget? child;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
