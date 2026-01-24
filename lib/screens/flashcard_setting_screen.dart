import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlashcardSettingScreen extends StatefulWidget {
  final SetModel set;

  const FlashcardSettingScreen({super.key, required this.set});

  @override
  State<FlashcardSettingScreen> createState() => _FlashcardSettingScreenState();
}

class _FlashcardSettingScreenState extends State<FlashcardSettingScreen> {
  final FlashcardSetService _setService = FlashcardSetService();
  late SetModel _currentSet;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSet = widget.set;
  }

  Future<void> _refreshSet() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final updatedSet = await _setService.getSet(userId, widget.set.id!);
    if (updatedSet != null) {
      setState(() {
        _currentSet = updatedSet;
      });
    }
  }

  void _showAddCardDialog() {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final tagsController = TextEditingController();
    Difficulty selectedDifficulty = Difficulty.medium;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Add New Card',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  decoration: InputDecoration(
                    labelText: 'Question',
                    hintText: 'Enter the question',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: answerController,
                  decoration: InputDecoration(
                    labelText: 'Answer',
                    hintText: 'Enter the answer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'e.g., biology, cells, organisms',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Difficulty',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<Difficulty>(
                  segments: const [
                    ButtonSegment(value: Difficulty.easy, label: Text('Easy')),
                    ButtonSegment(
                      value: Difficulty.medium,
                      label: Text('Medium'),
                    ),
                    ButtonSegment(value: Difficulty.hard, label: Text('Hard')),
                  ],
                  selected: {selectedDifficulty},
                  onSelectionChanged: (Set<Difficulty> selected) {
                    setDialogState(() {
                      selectedDifficulty = selected.first;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (questionController.text.trim().isEmpty ||
                    answerController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Question and answer are required'),
                    ),
                  );
                  return;
                }

                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) return;

                final tags = tagsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final newCard = Flashcard(
                  question: questionController.text.trim(),
                  answer: answerController.text.trim(),
                  tags: tags,
                  difficulty: selectedDifficulty,
                );

                final success = await _setService.addCard(
                  userId,
                  _currentSet.id!,
                  newCard,
                );

                if (success) {
                  await _refreshSet();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Card added successfully')),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add card')),
                    );
                  }
                }
              },
              child: const Text('Add Card'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCardDialog(Flashcard card, int index) {
    final questionController = TextEditingController(text: card.question);
    final answerController = TextEditingController(text: card.answer);
    final tagsController = TextEditingController(text: card.tags.join(', '));
    Difficulty selectedDifficulty = card.difficulty;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Edit Card',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: questionController,
                  decoration: InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: answerController,
                  decoration: InputDecoration(
                    labelText: 'Answer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags (comma separated)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Difficulty',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<Difficulty>(
                  segments: const [
                    ButtonSegment(value: Difficulty.easy, label: Text('Easy')),
                    ButtonSegment(
                      value: Difficulty.medium,
                      label: Text('Medium'),
                    ),
                    ButtonSegment(value: Difficulty.hard, label: Text('Hard')),
                  ],
                  selected: {selectedDifficulty},
                  onSelectionChanged: (Set<Difficulty> selected) {
                    setDialogState(() {
                      selectedDifficulty = selected.first;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (questionController.text.trim().isEmpty ||
                    answerController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Question and answer are required'),
                    ),
                  );
                  return;
                }

                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId == null) return;

                final tags = tagsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final updatedCard = Flashcard(
                  question: questionController.text.trim(),
                  answer: answerController.text.trim(),
                  tags: tags,
                  difficulty: selectedDifficulty,
                );

                // Update the card in the set
                final updatedCards = List<Flashcard>.from(_currentSet.cards);
                updatedCards[index] = updatedCard;

                final updatedSet = SetModel(
                  id: _currentSet.id,
                  title: _currentSet.title,
                  description: _currentSet.description,
                  cards: updatedCards,
                  dateAdded: _currentSet.dateAdded,
                  sessions: _currentSet.sessions,
                  fileType: _currentSet.fileType,
                  fileUrl: _currentSet.fileUrl,
                  fileName: _currentSet.fileName,
                );

                final success = await _setService.updateSet(
                  userId,
                  _currentSet.id!,
                  updatedSet,
                );

                if (success) {
                  await _refreshSet();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Card updated successfully'),
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update card')),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCard(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final updatedCards = List<Flashcard>.from(_currentSet.cards);
    updatedCards.removeAt(index);

    final updatedSet = SetModel(
      id: _currentSet.id,
      title: _currentSet.title,
      description: _currentSet.description,
      cards: updatedCards,
      dateAdded: _currentSet.dateAdded,
      sessions: _currentSet.sessions,
      fileType: _currentSet.fileType,
      fileUrl: _currentSet.fileUrl,
      fileName: _currentSet.fileName,
    );

    final success = await _setService.updateSet(
      userId,
      _currentSet.id!,
      updatedSet,
    );

    if (success) {
      await _refreshSet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card deleted successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete card')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Cards',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: colors.surface.withAlpha(230),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      bottom: BorderSide(color: colors.outline.withAlpha(128)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentSet.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currentSet.cards.length} cards',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cards list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentSet.cards.length,
                    itemBuilder: (context, index) {
                      final card = _currentSet.cards[index];
                      return _CardListItem(
                        card: card,
                        index: index,
                        onEdit: () => _showEditCardDialog(card, index),
                        onDelete: () => _deleteCard(index),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCardDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
        backgroundColor: colors.primary,
      ),
    );
  }
}

class _CardListItem extends StatelessWidget {
  final Flashcard card;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardListItem({
    required this.card,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.medium:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Q${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(
                          card.difficulty,
                        ).withAlpha(26),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        card.difficulty.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getDifficultyColor(card.difficulty),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      color: colors.onSurface,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  card.question,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.answer,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: colors.secondary,
                    height: 1.4,
                  ),
                ),
                if (card.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: card.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.outline.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colors.onSurface.withAlpha(180),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
