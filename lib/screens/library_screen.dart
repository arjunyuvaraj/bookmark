import 'dart:convert';
import 'package:bookmark/models/note_model.dart';
import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/services/notes_service.dart';
import 'package:bookmark/services/prompt_service.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/screens/flashcard_view_screen.dart';
import 'package:bookmark/theme/color_scheme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:hugeicons/hugeicons.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  NoteModel? _selectedNote;

  void _selectNote(NoteModel? note) {
    setState(() {
      _selectedNote = note;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Please Login"));
    }
    String currentUid = currentUser.uid;

    return StreamBuilder<List<NoteModel>>(
      stream: NotesService().streamUserNotes(currentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final notes = snapshot.data ?? [];

        if (notes.isEmpty) {
          return _buildEmptyState(context);
        }

        // If a note is selected, show the note detail view
        if (_selectedNote != null) {
          // Check if the selected note still exists
          final noteStillExists = notes.any((n) => n.id == _selectedNote!.id);
          if (!noteStillExists) {
            // Note was deleted, clear selection
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _selectNote(null);
            });
            return _buildNotesList(notes);
          }
          return _NoteDetailView(
            note: _selectedNote!,
            onBack: () => _selectNote(null),
            onDeleted: () => _selectNote(null),
          );
        }

        return _buildNotesList(notes);
      },
    );
  }

  Widget _buildNotesList(List<NoteModel> notes) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.length,
      itemBuilder: (BuildContext context, int index) {
        final NoteModel note = notes[index];
        return NoteCard(
          note: note,
          onTap: () => _selectNote(note),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedNote,
            size: 48,
            color: colorScheme.onSurface.withAlpha(102),
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload content to generate study notes',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(102),
            ),
          ),
        ],
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  dynamic _getSourceIcon(SourceType type) {
    switch (type) {
      case SourceType.pdf:
        return HugeIcons.strokeRoundedPdf01;
      case SourceType.image:
        return HugeIcons.strokeRoundedImage01;
      case SourceType.video:
        return HugeIcons.strokeRoundedPlayCircle;
      case SourceType.url:
        return HugeIcons.strokeRoundedLink01;
      case SourceType.text:
        return HugeIcons.strokeRoundedTextFont;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      note.subject,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  HugeIcon(
                    icon: _getSourceIcon(note.sourceType),
                    size: 16,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(note.createdAt),
                    style: TextStyle(
                      color: colorScheme.onSurface.withAlpha(153),
                      fontSize: 14,
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

/// Inline note detail view (keeps sidebar visible)
class _NoteDetailView extends StatefulWidget {
  final NoteModel note;
  final VoidCallback onBack;
  final VoidCallback onDeleted;

  const _NoteDetailView({
    required this.note,
    required this.onBack,
    required this.onDeleted,
  });

  @override
  State<_NoteDetailView> createState() => _NoteDetailViewState();
}

class _NoteDetailViewState extends State<_NoteDetailView> {
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
      final result = await _promptService.generateFlashcardsFromNotes(widget.note.notes);
      final cleanResult = _cleanJsonResponse(result);
      final jsonData = jsonDecode(cleanResult) as Map<String, dynamic>;

      final cards = (jsonData['cards'] as List?)
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

      // Create set and get the ID back
      final setId = await _flashcardService.createSet(_userId!, set);

      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingType = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cards.length} flashcards created!'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Create a new set with the ID for navigation
        final setWithId = SetModel(
          id: setId,
          title: set.title,
          description: set.description,
          fileType: set.fileType,
          cards: cards,
        );

        // Navigate to flashcard practice (full screen)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashcardPracticeScreen(set: setWithId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingType = null;
        });

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

  Future<void> _generateQuiz() async {
    if (_userId == null) return;

    setState(() {
      _isGenerating = true;
      _generatingType = 'quiz';
    });

    try {
      final result = await _promptService.generateQuizFromNotes(widget.note.notes);
      final cleanResult = _cleanJsonResponse(result);
      final jsonData = jsonDecode(cleanResult) as Map<String, dynamic>;

      final questions = (jsonData['questions'] as List?)
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

        // Navigate to quiz screen (full screen)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _QuizScreen(
              title: widget.note.title,
              questions: questions,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _generatingType = null;
        });

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

  Future<void> _deleteNote() async {
    if (_userId == null || widget.note.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
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
        widget.onDeleted();
      }
    }
  }

  String _cleanJsonResponse(String response) {
    String cleaned = response.trim();

    // Remove markdown code fences
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    // Try to find JSON object/array if there's extra text
    final jsonStart = cleaned.indexOf('{');
    final arrayStart = cleaned.indexOf('[');
    int start = -1;
    int end = -1;

    if (jsonStart != -1 && (arrayStart == -1 || jsonStart < arrayStart)) {
      start = jsonStart;
      end = cleaned.lastIndexOf('}');
    } else if (arrayStart != -1) {
      start = arrayStart;
      end = cleaned.lastIndexOf(']');
    }

    if (start != -1 && end != -1 && end > start) {
      cleaned = cleaned.substring(start, end + 1);
    }

    // Try parsing as-is first
    try {
      jsonDecode(cleaned);
      return cleaned.trim();
    } catch (_) {
      // Continue with repair
    }

    // Fix common JSON issues
    cleaned = _fixJsonString(cleaned);

    return cleaned.trim();
  }

  String _fixJsonString(String json) {
    final buffer = StringBuffer();
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < json.length; i++) {
      final char = json[i];
      final codeUnit = char.codeUnitAt(0);

      if (escaped) {
        if ('"\\/bfnrtu'.contains(char)) {
          buffer.write(char);
        } else {
          buffer.write('\\');
          buffer.write(char);
        }
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        buffer.write(char);
        continue;
      }

      if (char == '"') {
        inString = !inString;
        buffer.write(char);
        continue;
      }

      if (inString) {
        if (char == '\n') {
          buffer.write('\\n');
          continue;
        }
        if (char == '\r') {
          continue;
        }
        if (char == '\t') {
          buffer.write('\\t');
          continue;
        }
        if (codeUnit < 32) {
          buffer.write('\\u${codeUnit.toRadixString(16).padLeft(4, '0')}');
          continue;
        }
      }

      buffer.write(char);
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Header with back button and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    color: textColor,
                    size: 24,
                  ),
                  onPressed: widget.onBack,
                  tooltip: 'Back to library',
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.note.title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Three-dot menu with all actions
                PopupMenuButton<String>(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMoreVertical,
                    color: textColor,
                    size: 24,
                  ),
                  enabled: !_isGenerating,
                  onSelected: (value) {
                    switch (value) {
                      case 'flashcards':
                        _generateFlashcards();
                        break;
                      case 'quiz':
                        _generateQuiz();
                        break;
                      case 'delete':
                        _deleteNote();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'flashcards',
                      child: Row(
                        children: [
                          if (_isGenerating && _generatingType == 'flashcards')
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          else
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCards01,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            _isGenerating && _generatingType == 'flashcards'
                                ? 'Generating...'
                                : 'Generate Flashcards',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'quiz',
                      child: Row(
                        children: [
                          if (_isGenerating && _generatingType == 'quiz')
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          else
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedQuiz02,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            _isGenerating && _generatingType == 'quiz'
                                ? 'Generating...'
                                : 'Practice Quiz',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
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
          ),
          // Subject badge and date
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  constraints: const BoxConstraints(maxWidth: 800),
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
        ],
      ),
    );
  }
}

/// Quiz screen for practicing with generated questions
class _QuizScreen extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;

  const _QuizScreen({
    required this.title,
    required this.questions,
  });

  @override
  State<_QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<_QuizScreen> {
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
      return _buildResultsScreen(theme, colorScheme, bgColor, textColor, subtitleColor);
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
                          color: bgColor ?? (isDark ? darkSurface : lightSurface),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: borderColor ?? colorScheme.outline.withAlpha(50),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    _currentIndex < widget.questions.length - 1 ? 'Next Question' : 'See Results',
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  /// Preprocess the text to convert escape sequences to actual characters
  String _preprocessText(String input) {
    final buffer = StringBuffer();
    int i = 0;

    while (i < input.length) {
      if (input[i] == '\\' && i + 1 < input.length) {
        final nextChar = input[i + 1];
        switch (nextChar) {
          case 'n':
            buffer.write('\n');
            i += 2;
            break;
          case 't':
            buffer.write('\t');
            i += 2;
            break;
          case 'r':
            buffer.write('\r');
            i += 2;
            break;
          case '"':
            buffer.write('"');
            i += 2;
            break;
          case '\\':
            buffer.write('\\');
            i += 2;
            break;
          case '\$':
            // Keep \$ for LaTeX
            buffer.write(r'\$');
            i += 2;
            break;
          default:
            // Keep other escape sequences as-is for LaTeX (like \frac, \sqrt)
            buffer.write(input[i]);
            i++;
        }
      } else {
        buffer.write(input[i]);
        i++;
      }
    }

    return buffer.toString();
  }

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
    // Preprocess the text to handle escape sequences
    final processedText = _preprocessText(text);
    final parts = _splitByLatex(processedText);

    for (final part in parts) {
      if (part.isLatex) {
        widgets.add(_buildLatexWidget(part));
      } else if (part.content.trim().isNotEmpty) {
        widgets.add(_buildMarkdownWidget(part.content));
      }
    }

    return widgets.isEmpty
        ? [SelectableText(text, style: TextStyle(color: textColor, fontSize: 15, height: 1.6))]
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
        h1: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
        h2: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
        h3: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold, height: 1.4),
        h4: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold, height: 1.4),
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
        blockquote: TextStyle(color: textColor.withAlpha(180), fontStyle: FontStyle.italic),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12),
        listBullet: TextStyle(color: textColor),
        tableHead: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        tableBody: TextStyle(color: textColor),
        tableBorder: TableBorder.all(color: borderColor, width: 1),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: borderColor, width: 1),
          ),
        ),
      ),
    );
  }

  List<_LatexPart> _splitByLatex(String input) {
    final parts = <_LatexPart>[];

    // Pattern for block LaTeX: $$...$$ or \[...\]
    final blockPattern = RegExp(r'\$\$([\s\S]*?)\$\$|\\\[([\s\S]*?)\\\]');
    // Pattern for inline LaTeX: $...$ or \(...\) - but not $$
    final inlinePattern = RegExp(r'(?<!\$)\$(?!\$)([^\$\n]+?)\$(?!\$)|\\\((.*?)\\\)');

    int lastEnd = 0;

    // Process block LaTeX first
    final blockMatches = blockPattern.allMatches(input).toList();
    for (final match in blockMatches) {
      if (match.start > lastEnd) {
        parts.add(_LatexPart(input.substring(lastEnd, match.start), false, false));
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
        parts.add(_LatexPart(text.substring(lastEnd, match.start), false, false));
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
