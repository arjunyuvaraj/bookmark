import 'dart:convert';
import 'package:bookmark/models/note_model.dart';
import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/services/notes_service.dart';
import 'package:bookmark/services/prompt_service.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/services/user_stats_service.dart';
import 'package:bookmark/screens/flashcard_view_screen.dart';
import 'package:bookmark/screens/flashcard_setting_screen.dart';
import 'package:bookmark/theme/color_scheme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:hugeicons/hugeicons.dart';

// Enum to filter content type
enum ContentType { all, notes, flashcards }

// Animation constants for consistent timing
const Duration _kAnimationDuration = Duration(milliseconds: 200);
const Curve _kAnimationCurve = Curves.easeOutCubic;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  NoteModel? _selectedNote;
  SetModel? _selectedSet;
  ContentType _contentFilter = ContentType.all;
  final TextEditingController _searchController = TextEditingController();

  void _selectNote(NoteModel? note) {
    setState(() {
      _selectedNote = note;
      _selectedSet = null;
    });
  }

  void _selectSet(SetModel? set) {
    setState(() {
      _selectedSet = set;
      _selectedNote = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      builder: (context, notesSnapshot) {
        return StreamBuilder<List<SetModel>>(
          stream: FlashcardSetService().streamUserSets(currentUid),
          builder: (context, setsSnapshot) {
            if (notesSnapshot.connectionState == ConnectionState.waiting ||
                setsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (notesSnapshot.hasError) {
              return Center(child: Text("Error: ${notesSnapshot.error}"));
            }
            if (setsSnapshot.hasError) {
              return Center(child: Text("Error: ${setsSnapshot.error}"));
            }

            final notes = notesSnapshot.data ?? [];
            final sets = setsSnapshot.data ?? [];

            // If a note is selected, show the note detail view
            if (_selectedNote != null) {
              final noteStillExists = notes.any(
                (n) => n.id == _selectedNote!.id,
              );
              if (!noteStillExists) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _selectNote(null);
                });
              } else {
                return _NoteDetailView(
                  note: _selectedNote!,
                  onBack: () => _selectNote(null),
                  onDeleted: () => _selectNote(null),
                );
              }
            }

            // If a set is selected, show the set settings view
            if (_selectedSet != null) {
              final setStillExists = sets.any((s) => s.id == _selectedSet!.id);
              if (!setStillExists) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _selectSet(null);
                });
              } else {
                return FlashcardSettingScreen(set: _selectedSet!);
              }
            }

            // Use ListenableBuilder to rebuild only when search text changes
            return ListenableBuilder(
              listenable: _searchController,
              builder: (context, child) {
                final query = _searchController.text.toLowerCase();

                // Filter based on search query
                final filteredNotes = query.isEmpty
                    ? notes
                    : notes.where((note) =>
                        note.title.toLowerCase().contains(query) ||
                        note.subject.toLowerCase().contains(query)
                      ).toList();

                final filteredSets = query.isEmpty
                    ? sets
                    : sets.where((set) =>
                        set.title.toLowerCase().contains(query) ||
                        set.description.toLowerCase().contains(query)
                      ).toList();

                return _buildContentList(filteredNotes, filteredSets);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContentList(List<NoteModel> notes, List<SetModel> sets) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Filter content based on selected type
    final displayNotes =
        _contentFilter == ContentType.flashcards ? <NoteModel>[] : notes;
    final displaySets =
        _contentFilter == ContentType.notes ? <SetModel>[] : sets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Header with search and filters
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page title
                Text(
                  'Library',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                // Minimal search bar
                _SearchBar(
                  controller: _searchController,
                  theme: theme,
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                // Minimal filter tabs
                _FilterTabs(
                  selectedFilter: _contentFilter,
                  notesCount: notes.length,
                  flashcardsCount: sets.length,
                  onFilterChanged: (filter) {
                    setState(() => _contentFilter = filter);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Subtle divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? darkBorder : lightBorder,
          ),
          // Content list or empty state
          Expanded(
            child: displayNotes.isEmpty && displaySets.isEmpty
                ? _buildEmptyContent(theme, colorScheme)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    itemCount: _getItemCount(displayNotes, displaySets),
                    itemBuilder: (context, index) {
                      return _buildListItem(
                        context,
                        index,
                        displayNotes,
                        displaySets,
                        theme,
                        colorScheme,
                      );
                    },
                  ),
          ),
        ],
      );
  }

  int _getItemCount(List<NoteModel> notes, List<SetModel> sets) {
    int count = 0;
    if (notes.isNotEmpty) {
      count += 1 + notes.length; // Header + items
    }
    if (sets.isNotEmpty) {
      count += 1 + sets.length; // Header + items
    }
    return count;
  }

  Widget _buildListItem(
    BuildContext context,
    int index,
    List<NoteModel> notes,
    List<SetModel> sets,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Calculate which section and item we're in
    int notesSection = notes.isNotEmpty ? 1 + notes.length : 0;

    if (notes.isNotEmpty && index == 0) {
      // Notes header
      return _buildSectionHeader(
        theme,
        colorScheme,
        'Notes',
        notes.length,
        HugeIcons.strokeRoundedNote,
        index,
      );
    } else if (notes.isNotEmpty && index > 0 && index <= notes.length) {
      // Note item
      final note = notes[index - 1];
      return NoteCard(
        key: ValueKey('note_${note.id}'),
        note: note,
        onTap: () => _selectNote(note),
      );
    } else if (sets.isNotEmpty && index == notesSection) {
      // Flashcards header
      return _buildSectionHeader(
        theme,
        colorScheme,
        'Flashcards',
        sets.length,
        HugeIcons.strokeRoundedCards01,
        index,
      );
    } else if (sets.isNotEmpty && index > notesSection) {
      // Flashcard item
      final set = sets[index - notesSection - 1];
      return FlashcardSetCard(
        key: ValueKey('set_${set.id}'),
        set: set,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashcardPracticeScreen(set: set),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    ColorScheme colorScheme,
    String title,
    int count,
    dynamic icon,
    int index,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: index == 0 ? 0 : 24,
        bottom: 12,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(150),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withAlpha(150),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedNote,
                size: 28,
                color: colorScheme.onSurface.withAlpha(80),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty ? 'No content yet' : 'No results found',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface.withAlpha(180),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Upload content to generate study notes'
                : 'Try a different search term',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal filter tabs inspired by Notion
class _FilterTabs extends StatelessWidget {
  final ContentType selectedFilter;
  final int notesCount;
  final int flashcardsCount;
  final ValueChanged<ContentType> onFilterChanged;

  const _FilterTabs({
    required this.selectedFilter,
    required this.notesCount,
    required this.flashcardsCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        _FilterTab(
          label: 'All',
          count: notesCount + flashcardsCount,
          isSelected: selectedFilter == ContentType.all,
          onTap: () => onFilterChanged(ContentType.all),
          theme: theme,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 4),
        _FilterTab(
          label: 'Notes',
          count: notesCount,
          isSelected: selectedFilter == ContentType.notes,
          onTap: () => onFilterChanged(ContentType.notes),
          theme: theme,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 4),
        _FilterTab(
          label: 'Flashcards',
          count: flashcardsCount,
          isSelected: selectedFilter == ContentType.flashcards,
          onTap: () => onFilterChanged(ContentType.flashcards),
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _FilterTab extends StatefulWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _FilterTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.colorScheme,
  });

  @override
  State<_FilterTab> createState() => _FilterTabState();
}

class _FilterTabState extends State<_FilterTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _kAnimationDuration,
          curve: _kAnimationCurve,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.colorScheme.onSurface.withAlpha(20)
                : (_isHovered
                    ? widget.colorScheme.onSurface.withAlpha(10)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: _kAnimationDuration,
                style: widget.theme.textTheme.labelMedium!.copyWith(
                  color: widget.isSelected
                      ? widget.colorScheme.onSurface
                      : widget.colorScheme.onSurface.withAlpha(150),
                  fontWeight:
                      widget.isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
                child: Text(widget.label),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: _kAnimationDuration,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.colorScheme.onSurface.withAlpha(25)
                      : widget.colorScheme.onSurface.withAlpha(12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${widget.count}',
                  style: widget.theme.textTheme.labelSmall?.copyWith(
                    color: widget.isSelected
                        ? widget.colorScheme.onSurface.withAlpha(200)
                        : widget.colorScheme.onSurface.withAlpha(120),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minimal search bar that uses controller directly
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isDark;

  const _SearchBar({
    required this.controller,
    required this.theme,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? darkSurface : lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? darkBorder : lightBorder,
          width: 1,
        ),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withAlpha(100),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 18,
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 38,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedCancel01,
                        size: 16,
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                      onPressed: controller.clear,
                      splashRadius: 16,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}

class NoteCard extends StatefulWidget {
  final NoteModel note;
  final VoidCallback onTap;

  const NoteCard({super.key, required this.note, required this.onTap});

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isHovered = false;

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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: _kAnimationDuration,
            curve: _kAnimationCurve,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isDark
                      ? colorScheme.onSurface.withAlpha(15)
                      : colorScheme.onSurface.withAlpha(8))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Minimal icon
                HugeIcon(
                  icon: HugeIcons.strokeRoundedNote,
                  size: 18,
                  color: colorScheme.onSurface.withAlpha(150),
                ),
                const SizedBox(width: 12),
                // Title and metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.note.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          HugeIcon(
                            icon: _getSourceIcon(widget.note.sourceType),
                            size: 12,
                            color: colorScheme.onSurface.withAlpha(100),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(widget.note.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface.withAlpha(100),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Subject tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.note.subject,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ),
                // Hover arrow indicator
                AnimatedOpacity(
                  duration: _kAnimationDuration,
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 16,
                      color: colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FlashcardSetCard extends StatefulWidget {
  final SetModel set;
  final VoidCallback onTap;

  const FlashcardSetCard({super.key, required this.set, required this.onTap});

  @override
  State<FlashcardSetCard> createState() => _FlashcardSetCardState();
}

class _FlashcardSetCardState extends State<FlashcardSetCard> {
  bool _isHovered = false;

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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: _kAnimationDuration,
            curve: _kAnimationCurve,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isDark
                      ? colorScheme.onSurface.withAlpha(15)
                      : colorScheme.onSurface.withAlpha(8))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Minimal icon
                HugeIcon(
                  icon: HugeIcons.strokeRoundedCards01,
                  size: 18,
                  color: colorScheme.onSurface.withAlpha(150),
                ),
                const SizedBox(width: 12),
                // Title and metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.set.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.set.cards.length} cards · ${_formatDate(widget.set.dateAdded)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                    ],
                  ),
                ),
                // Card count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCards01,
                        size: 12,
                        color: colorScheme.onSurface.withAlpha(120),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.set.cards.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withAlpha(150),
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Hover arrow indicator
                AnimatedOpacity(
                  duration: _kAnimationDuration,
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 16,
                      color: colorScheme.onSurface.withAlpha(100),
                    ),
                  ),
                ),
              ],
            ),
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
  final UserStatsService _statsService = UserStatsService();
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

        // Navigate to quiz screen (full screen) and wait for result
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => _QuizScreen(
              title: widget.note.title,
              questions: questions,
              userId: _userId!,
              noteId: widget.note.id ?? '',
            ),
          ),
        );

        // Record quiz completion in stats if quiz was completed
        if (result != null && result['completed'] == true) {
          final score = result['score'] as int;
          final totalQuestions = result['totalQuestions'] as int;

          await _statsService.recordQuizCompleted(
            userId: _userId!,
            setId: widget.note.id ?? 'note_quiz',
            setTitle: widget.note.title,
            score: score,
            totalQuestions: totalQuestions,
          );
        }
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Minimal header with back button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // Back button
                _HoverIconButton(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  onTap: widget.onBack,
                  tooltip: 'Back to library',
                  colorScheme: colorScheme,
                  isDark: isDark,
                ),
                const Spacer(),
                // Action buttons row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: HugeIcons.strokeRoundedCards01,
                      label: 'Flashcards',
                      isLoading:
                          _isGenerating && _generatingType == 'flashcards',
                      onTap: _generateFlashcards,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: HugeIcons.strokeRoundedQuiz02,
                      label: 'Quiz',
                      isLoading: _isGenerating && _generatingType == 'quiz',
                      onTap: _generateQuiz,
                      colorScheme: colorScheme,
                      isDark: isDark,
                      theme: theme,
                    ),
                    const SizedBox(width: 8),
                    _HoverIconButton(
                      icon: HugeIcons.strokeRoundedDelete02,
                      onTap: _deleteNote,
                      tooltip: 'Delete note',
                      colorScheme: colorScheme,
                      isDark: isDark,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Title and metadata section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.note.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                // Metadata row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.note.subject,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(widget.note.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Divider
          Divider(height: 1, thickness: 1, color: borderColor),
          // Notes content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
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

/// Minimal hover icon button
class _HoverIconButton extends StatefulWidget {
  final dynamic icon;
  final VoidCallback onTap;
  final String tooltip;
  final ColorScheme colorScheme;
  final bool isDark;
  final bool isDestructive;

  const _HoverIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.colorScheme,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isDestructive
        ? Colors.red.withAlpha(20)
        : widget.colorScheme.onSurface.withAlpha(15);
    final iconColor = widget.isDestructive
        ? (_isHovered ? Colors.red : widget.colorScheme.onSurface.withAlpha(150))
        : widget.colorScheme.onSurface.withAlpha(_isHovered ? 200 : 150);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: _kAnimationDuration,
            curve: _kAnimationCurve,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: HugeIcon(
              icon: widget.icon,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal action button with label
class _ActionButton extends StatefulWidget {
  final dynamic icon;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isDark;
  final ThemeData theme;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onTap,
    required this.colorScheme,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: _kAnimationDuration,
          curve: _kAnimationCurve,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.colorScheme.onSurface.withAlpha(15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.colorScheme.onSurface.withAlpha(150),
                  ),
                )
              else
                HugeIcon(
                  icon: widget.icon,
                  size: 14,
                  color: widget.colorScheme.onSurface.withAlpha(150),
                ),
              const SizedBox(width: 6),
              Text(
                widget.isLoading ? 'Generating...' : widget.label,
                style: widget.theme.textTheme.labelSmall?.copyWith(
                  color: widget.colorScheme.onSurface.withAlpha(180),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quiz screen for practicing with generated questions
class _QuizScreen extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;
  final String userId;
  final String noteId;

  const _QuizScreen({
    required this.title,
    required this.questions,
    required this.userId,
    required this.noteId,
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
          onPressed: () {
            // Return null when backing out without completing
            Navigator.pop(context, null);
          },
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
          onPressed: () {
            // Return quiz completion data
            Navigator.pop(context, {
              'completed': true,
              'score': _correctCount,
              'totalQuestions': widget.questions.length,
            });
          },
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
                      onPressed: () {
                        // Return quiz completion data
                        Navigator.pop(context, {
                          'completed': true,
                          'score': _correctCount,
                          'totalQuestions': widget.questions.length,
                        });
                      },
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

// Keep the existing classes: _NotesMarkdownContent, _SafeLatex, _LatexPart

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
