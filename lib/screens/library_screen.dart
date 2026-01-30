import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/screens/flashcard_view_screen.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text("Please Login"));
    }
    String currentUid = currentUser.uid;
    return FutureBuilder(
      future: FlashcardSetService().getUserSets(currentUid),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final sets = snapshot.data!;
          if (sets.isEmpty) {
            return const Center(child: Text("No flashcard sets yet"));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sets.length,
            itemBuilder: (BuildContext context, int index) {
              final SetModel set = sets[index];
              return FlashcardSetCard(
                set: set.toJson(),
                setModel: set,
                userId: currentUid,
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class FlashcardSetCard extends StatelessWidget {
  final Map<String, dynamic> set;
  final SetModel setModel;
  final String userId;

  const FlashcardSetCard({
    super.key,
    required this.set,
    required this.setModel,
    required this.userId,
  });

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: setModel.title);
    final descriptionController = TextEditingController(
      text: setModel.description,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Set'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Title cannot be empty')),
                );
                return;
              }

              final updatedSet = setModel.copyWith(
                title: titleController.text.trim(),
                description: descriptionController.text.trim(),
              );

              final success = await FlashcardSetService().updateSet(
                userId,
                setModel.id!,
                updatedSet,
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Set updated successfully')),
                  );
                  // Refresh the screen
                  (context as Element).markNeedsBuild();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update set')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Set'),
        content: Text(
          'Are you sure you want to delete "${setModel.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await FlashcardSetService().deleteSet(
                userId,
                setModel.id!,
                fileUrl: setModel.fileUrl,
              );

              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Set deleted successfully')),
                  );
                  // Refresh the screen
                  (context as Element).markNeedsBuild();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete set')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = set['title'] ?? 'Untitled Set';
    final description = set['description'] ?? '';
    final cardCount = (set['cards'] as List?)?.length ?? 0;
    final sessions = set['sessions'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FlashcardPracticeScreen(set: SetModel.fromJson(set)),
            ),
          );
        },
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
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    children: [
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
                          '$cardCount cards',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDialog(context);
                          } else if (value == 'delete') {
                            _showDeleteDialog(context);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 16,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$sessions sessions',
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
