import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bookmark/components/upload_dialog.dart';
import 'package:bookmark/services/user_stats_service.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/models/flashcard_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserStatsService _statsService = UserStatsService();
  final FlashcardSetService _flashcardService = FlashcardSetService();

  void _showUploadDialog(BuildContext context, {bool customMode = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadDialog(startInCustomMode: customMode),
    );
  }

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'there';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, displayName, theme, colorScheme),
              const SizedBox(height: 40),
              if (_userId != null) ...[
                _buildDashboard(context, theme, colorScheme),
              ] else ...[
                _buildEmptyState(theme, colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String displayName,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withAlpha(128),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        _CreateNewButton(
          onUpload: () => _showUploadDialog(context),
          onCustom: () => _showUploadDialog(context, customMode: true),
        ),
      ],
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Row
        StreamBuilder<UserStats>(
          stream: _statsService.streamUserStats(_userId!),
          builder: (context, statsSnapshot) {
            final stats = statsSnapshot.data ?? UserStats();

            return StreamBuilder<List<SetModel>>(
              stream: _flashcardService.streamUserSets(_userId!),
              builder: (context, setsSnapshot) {
                final sets = setsSnapshot.data ?? [];

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _StreakCard(
                        currentStreak: stats.currentStreak,
                        longestStreak: stats.longestStreak,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _StatCard(
                        value: '${stats.totalCardsStudied}',
                        label: 'Cards Studied',
                        icon: HugeIcons.strokeRoundedCards01,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _StatCard(
                        value: '${sets.length}',
                        label: 'Flashcard Sets',
                        icon: HugeIcons.strokeRoundedFolder01,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _StatCard(
                        value: '${stats.accuracy.round()}%',
                        label: 'Quiz Accuracy',
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 32),

        // Bottom Row: Recent Activity and Study Goals
        SizedBox(
          height: 420,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _RecentActivityCard(
                  userId: _userId!,
                  statsService: _statsService,
                  theme: theme,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: StreamBuilder<UserStats>(
                  stream: _statsService.streamUserStats(_userId!),
                  builder: (context, snapshot) {
                    final stats = snapshot.data ?? UserStats();
                    return _StudyGoalsCard(
                      stats: stats,
                      theme: theme,
                      colorScheme: colorScheme,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Center(
        child: Column(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLogin01,
              size: 48,
              color: colorScheme.onSurface.withAlpha(102),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to track your progress',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CREATE NEW BUTTON
// ============================================================================

class _CreateNewButton extends StatefulWidget {
  final VoidCallback onUpload;
  final VoidCallback onCustom;

  const _CreateNewButton({required this.onUpload, required this.onCustom});

  @override
  State<_CreateNewButton> createState() => _CreateNewButtonState();
}

class _CreateNewButtonState extends State<_CreateNewButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 220,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(size.width - 220, size.height + 8),
              child: _DropdownMenu(
                onUpload: () {
                  _closeDropdown();
                  widget.onUpload();
                },
                onCustom: () {
                  _closeDropdown();
                  widget.onCustom();
                },
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: FilledButton(
        onPressed: _toggleDropdown,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: 18,
              color: colorScheme.onPrimary,
            ),
            const SizedBox(width: 8),
            const Text('Create New'),
            const SizedBox(width: 4),
            HugeIcon(
              icon: _isOpen
                  ? HugeIcons.strokeRoundedArrowUp01
                  : HugeIcons.strokeRoundedArrowDown01,
              size: 18,
              color: colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownMenu extends StatelessWidget {
  final VoidCallback onUpload;
  final VoidCallback onCustom;

  const _DropdownMenu({required this.onUpload, required this.onCustom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withAlpha(30),
      borderRadius: BorderRadius.circular(8),
      color: isDark ? colorScheme.surface : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outline.withAlpha(50)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DropdownItem(
              icon: HugeIcons.strokeRoundedCloudUpload,
              title: 'Upload Content',
              subtitle: 'Files, links, and text',
              onTap: onUpload,
              theme: theme,
              colorScheme: colorScheme,
            ),
            Divider(height: 1, color: colorScheme.outline.withAlpha(50)),
            _DropdownItem(
              icon: HugeIcons.strokeRoundedPencilEdit01,
              title: 'Custom Creation',
              subtitle: 'Build from scratch',
              onTap: onCustom,
              theme: theme,
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownItem extends StatefulWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _DropdownItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
    required this.colorScheme,
  });

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          color: _isHovered
              ? widget.colorScheme.onSurface.withAlpha(8)
              : Colors.transparent,
          child: Row(
            children: [
              HugeIcon(
                icon: widget.icon,
                size: 20,
                color: widget.colorScheme.onSurface.withAlpha(153),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: widget.theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: widget.theme.textTheme.bodySmall?.copyWith(
                        color: widget.colorScheme.onSurface.withAlpha(102),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STREAK CARD (Enhanced with prominent flame)
// ============================================================================

class _StreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _StreakCard({
    required this.currentStreak,
    required this.longestStreak,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final hasStreak = currentStreak > 0;

    // Muted flame color - slightly warmer when active
    final flameColor = hasStreak
        ? colorScheme.onSurface.withAlpha(180)
        : colorScheme.onSurface.withAlpha(80);

    return Container(
      height: 120,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(60)),
      ),
      child: Row(
        children: [
          // Simple flame icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedFire,
                size: 26,
                color: flameColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$currentStreak',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentStreak == 1 ? 'day streak' : 'day streak',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Best: $longestStreak days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(102),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STAT CARD
// ============================================================================

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final dynamic icon;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 120,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(60)),
      ),
      child: Row(
        children: [
          HugeIcon(
            icon: icon,
            size: 28,
            color: colorScheme.onSurface.withAlpha(120),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECENT ACTIVITY CARD
// ============================================================================

class _RecentActivityCard extends StatelessWidget {
  final String userId;
  final UserStatsService statsService;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _RecentActivityCard({
    required this.userId,
    required this.statsService,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<ActivityItem>>(
              stream: statsService.streamRecentActivity(userId, limit: 8),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onSurface.withAlpha(102),
                      ),
                    ),
                  );
                }

                final activities = snapshot.data ?? [];

                if (activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedClock01,
                          size: 32,
                          color: colorScheme.onSurface.withAlpha(60),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withAlpha(102),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _ActivityItemWidget(
                      activity: activity,
                      theme: theme,
                      colorScheme: colorScheme,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItemWidget extends StatelessWidget {
  final ActivityItem activity;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ActivityItemWidget({
    required this.activity,
    required this.theme,
    required this.colorScheme,
  });

  dynamic _getIconForType(String type) {
    switch (type) {
      case 'study':
        return HugeIcons.strokeRoundedCards01;
      case 'quiz':
        return HugeIcons.strokeRoundedCheckmarkCircle02;
      case 'created':
        return HugeIcons.strokeRoundedAddCircle;
      default:
        return HugeIcons.strokeRoundedCircle;
    }
  }

  Color _getColorForType(String type) {
    // Use muted, monochrome colors for minimal look
    return colorScheme.onSurface.withAlpha(150);
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getColorForType(activity.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: HugeIcon(
                icon: _getIconForType(activity.type),
                size: 16,
                color: typeColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              activity.title,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatTime(activity.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withAlpha(102),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STUDY GOALS CARD
// ============================================================================

class _StudyGoalsCard extends StatelessWidget {
  final UserStats stats;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _StudyGoalsCard({
    required this.stats,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Goals',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          _GoalProgress(
            label: 'Daily Cards',
            current: stats.cardsStudiedToday,
            target: stats.dailyGoalCards,
            icon: HugeIcons.strokeRoundedCards01,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 28),
          _GoalProgress(
            label: 'Weekly Sessions',
            current: stats.sessionsThisWeek,
            target: stats.weeklyGoalSessions,
            icon: HugeIcons.strokeRoundedCalendar03,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 28),
          _GoalProgress(
            label: 'Monthly Quizzes',
            current: stats.quizzesThisMonth,
            target: stats.monthlyGoalQuizzes,
            icon: HugeIcons.strokeRoundedCheckmarkCircle02,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final dynamic icon;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _GoalProgress({
    required this.label,
    required this.current,
    required this.target,
    required this.icon,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isComplete = current >= target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 18,
              color: colorScheme.onSurface.withAlpha(isComplete ? 180 : 120),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(180),
                ),
              ),
            ),
            Text(
              '$current / $target',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isComplete) ...[
              const SizedBox(width: 4),
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                size: 14,
                color: colorScheme.onSurface.withAlpha(180),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.onSurface.withAlpha(20),
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme.onSurface.withAlpha(isComplete ? 180 : 100),
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

