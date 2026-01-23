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
              return FlashcardSetCard(set: set.toJson());
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
  const FlashcardSetCard({super.key, required this.set});

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
          // Navigate to flashcard practice screen
          // Navigator.push(context, MaterialPageRoute(builder: (context) => FlashcardPracticeScreen(set: set)));
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
                    child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$cardCount cards', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withAlpha(153)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.history, size: 16, color: colorScheme.onSurface.withAlpha(153)),
                  const SizedBox(width: 4),
                  Text('$sessions sessions', style: TextStyle(color: colorScheme.onSurface.withAlpha(153), fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
