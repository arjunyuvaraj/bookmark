import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bookmark/models/note_model.dart';
import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/services/notes_service.dart';
import 'package:bookmark/services/prompt_service.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/screens/flashcard_view_screen.dart';
import 'package:bookmark/theme/color_scheme.dart';

class NoteViewScreen extends StatefulWidget {
  final NoteModel note;

  const NoteViewScreen({super.key, required this.note});

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  final NotesService _notesService = NotesService();
  final PromptService _promptService = PromptService();
  final FlashcardSetService _flashcardService = FlashcardSetService();
  bool _isGenerating = false;
  String? _generatingType;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _generateFlashcards() async {
    if (_userId == null) return;

    setState(() {
      _isGenerating = true;
      _generatingType = 'flashcards';
    });

    try {
      final result = await _promptService.generateFlashcardsFromNotes(
        widget.note.notes,
      );
      final cleanResult = _cleanJsonResponse(result);
      final jsonData = jsonDecode(cleanResult) as Map<String, dynamic>;

      final cards =
          (jsonData['cards'] as List?)
              ?.map((card) => Flashcard.fromJson(card as Map<String, dynamic>))
              .toList() ??
          [];

      if (cards.isEmpty) {
        throw Exception('No flashcards generated');
      }

      final set = SetModel(
        title: '${widget.note.title} - Flashcards',
        description: 'Generated from ${widget.note.title}',
        fileType: FileType.none,
        cards: cards,
      );

      // Create the set in Firebase and get the ID
      final setId = await _flashcardService.createSet(_userId!, set);

      if (setId == null) {
        throw Exception('Failed to save flashcard set');
      }

      // Update the set with the ID
      final setWithId = set.copyWith(id: setId);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingType = null;
        });

        // Navigate to flashcard practice
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashcardPracticeScreen(set: setWithId),
          ),
        );

        // Show success message after returning from practice screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${cards.length} flashcards created!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingType = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate flashcards: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _generateQuiz() async {
    if (_userId == null) return;

    setState(() {
      _isGenerating = true;
      _generatingType = 'quiz';
    });

    try {
      final result = await _promptService.generateQuizFromNotes(
        widget.note.notes,
      );
      final cleanResult = _cleanJsonResponse(result);
      final jsonData = jsonDecode(cleanResult) as Map<String, dynamic>;

      final questions =
          (jsonData['questions'] as List?)
              ?.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [];

      if (questions.isEmpty) {
        throw Exception('No quiz questions generated');
      }

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingType = null;
        });

        // Navigate to quiz screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                QuizScreen(title: widget.note.title, questions: questions),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingType = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate quiz: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteNote() async {
    if (_userId == null || widget.note.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notesService.deleteNote(_userId!, widget.note.id!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  String _cleanJsonResponse(String response) {
    String cleaned = response.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? darkBackground : lightBackground;
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;
    final borderColor = isDark ? darkBorder : lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: textColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.note.title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedMoreVertical,
              color: textColor,
              size: 24,
            ),
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  _deleteNote();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedDelete02,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Subject badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.note.subject,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(widget.note.createdAt),
                  style: TextStyle(color: subtitleColor, fontSize: 13),
                ),
              ],
            ),
          ),
          // Notes content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 768),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _NotesMarkdownContent(
                      text: widget.note.notes,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: HugeIcons.strokeRoundedCards01,
                    label: 'Flashcards',
                    isLoading: _isGenerating && _generatingType == 'flashcards',
                    onPressed: _isGenerating ? null : _generateFlashcards,
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: HugeIcons.strokeRoundedQuiz02,
                    label: 'Practice Quiz',
                    isLoading: _isGenerating && _generatingType == 'quiz',
                    onPressed: _isGenerating ? null : _generateQuiz,
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ActionButton extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        disabledBackgroundColor: colorScheme.onSurface.withAlpha(30),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: icon, size: 20, color: colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Quiz screen for practicing with generated questions
class QuizScreen extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;

  const QuizScreen({super.key, required this.title, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _showExplanation = false;
  int _correctCount = 0;
  bool _quizComplete = false;

  void _selectAnswer(int index) {
    if (_selectedAnswer != null) return;

    setState(() {
      _selectedAnswer = index;
      _showExplanation = true;
      if (index == widget.questions[_currentIndex].correctAnswer) {
        _correctCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showExplanation = false;
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
      _showExplanation = false;
      _correctCount = 0;
      _quizComplete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? darkBackground : lightBackground;
    final textColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;

    if (_quizComplete) {
      return _buildResultsScreen(
        theme,
        colorScheme,
        bgColor,
        textColor,
        subtitleColor,
      );
    }

    final question = widget.questions[_currentIndex];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: textColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Question ${_currentIndex + 1}/${widget.questions.length}',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: colorScheme.onSurface.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
            const SizedBox(height: 24),
            // Question
            Text(
              question.question,
              style: theme.textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            // Options
            Expanded(
              child: ListView.builder(
                itemCount: question.options.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedAnswer == index;
                  final isCorrect = index == question.correctAnswer;
                  final showResult = _selectedAnswer != null;

                  Color? bgColor;
                  Color? borderColor;
                  if (showResult) {
                    if (isCorrect) {
                      bgColor = Colors.green.withAlpha(26);
                      borderColor = Colors.green;
                    } else if (isSelected && !isCorrect) {
                      bgColor = Colors.red.withAlpha(26);
                      borderColor = Colors.red;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectAnswer(index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              bgColor ?? (isDark ? darkSurface : lightSurface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                borderColor ??
                                colorScheme.outline.withAlpha(50),
                            width: borderColor != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withAlpha(20),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : subtitleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: TextStyle(color: textColor),
                              ),
                            ),
                            if (showResult && isCorrect)
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                color: Colors.green,
                                size: 24,
                              ),
                            if (showResult && isSelected && !isCorrect)
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedCancel01,
                                color: Colors.red,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Explanation
            if (_showExplanation) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedIdea,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        question.explanation,
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _nextQuestion,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _currentIndex < widget.questions.length - 1
                        ? 'Next Question'
                        : 'See Results',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsScreen(
    ThemeData theme,
    ColorScheme colorScheme,
    Color bgColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final percentage = (_correctCount / widget.questions.length * 100).round();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            color: textColor,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quiz Complete',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: percentage >= 70
                      ? Colors.green.withAlpha(26)
                      : Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    '$percentage%',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: percentage >= 70 ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                percentage >= 70 ? 'Great job!' : 'Keep practicing!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You got $_correctCount out of ${widget.questions.length} questions correct',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: subtitleColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: colorScheme.outline),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _restartQuiz,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Markdown content with LaTeX support for notes
class _NotesMarkdownContent extends StatelessWidget {
  final String text;
  final bool isDark;
  final Color textColor;

  const _NotesMarkdownContent({
    required this.text,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final processedWidgets = _buildContentWidgets();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: processedWidgets,
    );
  }

  List<Widget> _buildContentWidgets() {
    final widgets = <Widget>[];
    final parts = _splitByLatex(text);

    for (final part in parts) {
      if (part.isLatex) {
        widgets.add(_buildLatexWidget(part));
      } else if (part.content.trim().isNotEmpty) {
        widgets.add(_buildMarkdownWidget(part.content));
      }
    }

    return widgets.isEmpty
        ? [
            SelectableText(
              text,
              style: TextStyle(color: textColor, fontSize: 15, height: 1.6),
            ),
          ]
        : widgets;
  }

  Widget _buildLatexWidget(_LatexPart part) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: part.isBlock ? 12 : 4),
      child: part.isBlock
          ? Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _SafeLatex(
                  latex: part.content,
                  textStyle: TextStyle(color: textColor, fontSize: 18),
                  isDark: isDark,
                ),
              ),
            )
          : _SafeLatex(
              latex: part.content,
              textStyle: TextStyle(color: textColor, fontSize: 15),
              isDark: isDark,
            ),
    );
  }

  Widget _buildMarkdownWidget(String content) {
    final borderColor = isDark ? darkBorder : lightBorder;
    final surfaceColor = isDark ? darkSurface : lightSurface;

    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: textColor, fontSize: 15, height: 1.6),
        h1: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        h2: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        h3: TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        h4: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
        strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
        code: TextStyle(
          color: textColor,
          backgroundColor: surfaceColor,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        codeblockDecoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(6),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquote: TextStyle(
          color: textColor.withAlpha(180),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderColor, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12),
        listBullet: TextStyle(color: textColor),
        tableHead: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        tableBody: TextStyle(color: textColor),
        tableBorder: TableBorder.all(color: borderColor, width: 1),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
      ),
    );
  }

  List<_LatexPart> _splitByLatex(String input) {
    final parts = <_LatexPart>[];

    // Pattern for block LaTeX: $$...$$ or \[...\]
    final blockPattern = RegExp(r'\$\$([\s\S]*?)\$\$|\\\[([\s\S]*?)\\\]');
    // Pattern for inline LaTeX: $...$ or \(...\) - but not $$
    final inlinePattern = RegExp(
      r'(?<!\$)\$(?!\$)([^\$\n]+?)\$(?!\$)|\\\((.*?)\\\)',
    );

    int lastEnd = 0;

    // Process block LaTeX first
    final blockMatches = blockPattern.allMatches(input).toList();
    for (final match in blockMatches) {
      if (match.start > lastEnd) {
        // Add text before this match (will process inline later)
        parts.add(
          _LatexPart(input.substring(lastEnd, match.start), false, false),
        );
      }
      final content = match.group(1) ?? match.group(2) ?? '';
      parts.add(_LatexPart(content.trim(), true, true));
      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      parts.add(_LatexPart(input.substring(lastEnd), false, false));
    }

    if (parts.isEmpty) {
      parts.add(_LatexPart(input, false, false));
    }

    // Now process inline LaTeX in non-LaTeX parts
    final finalParts = <_LatexPart>[];
    for (final part in parts) {
      if (part.isLatex) {
        finalParts.add(part);
      } else {
        finalParts.addAll(_processInlineLatex(part.content, inlinePattern));
      }
    }

    return finalParts.isEmpty ? [_LatexPart(input, false, false)] : finalParts;
  }

  List<_LatexPart> _processInlineLatex(String text, RegExp pattern) {
    final parts = <_LatexPart>[];
    int lastEnd = 0;

    final matches = pattern.allMatches(text).toList();
    for (final match in matches) {
      if (match.start > lastEnd) {
        parts.add(
          _LatexPart(text.substring(lastEnd, match.start), false, false),
        );
      }
      final content = match.group(1) ?? match.group(2) ?? '';
      if (content.isNotEmpty) {
        parts.add(_LatexPart(content.trim(), true, false));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      parts.add(_LatexPart(text.substring(lastEnd), false, false));
    }

    return parts.isEmpty ? [_LatexPart(text, false, false)] : parts;
  }
}

/// Safe LaTeX widget with error handling
class _SafeLatex extends StatelessWidget {
  final String latex;
  final TextStyle textStyle;
  final bool isDark;

  const _SafeLatex({
    required this.latex,
    required this.textStyle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? darkSurface : lightSurface;

    try {
      return Math.tex(
        latex,
        textStyle: textStyle,
        onErrorFallback: (error) {
          // Fallback to showing the raw LaTeX in a code-style format
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              latex,
              style: textStyle.copyWith(
                fontFamily: 'monospace',
                fontSize: (textStyle.fontSize ?? 15) - 1,
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Fallback for any other errors
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          latex,
          style: textStyle.copyWith(
            fontFamily: 'monospace',
            fontSize: (textStyle.fontSize ?? 15) - 1,
          ),
        ),
      );
    }
  }
}

/// Helper class for LaTeX parts
class _LatexPart {
  final String content;
  final bool isLatex;
  final bool isBlock;

  _LatexPart(this.content, this.isLatex, this.isBlock);
}
