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

  Widget _buildHeader(BuildContext context, String displayName, ThemeData theme, ColorScheme colorScheme) {
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

  Widget _buildDashboard(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
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
                      child: _StreakCard(
                        currentStreak: stats.currentStreak,
                        longestStreak: stats.longestStreak,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        value: '${stats.totalCardsStudied}',
                        label: 'Cards Studied',
                        icon: HugeIcons.strokeRoundedCards01,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        value: '${sets.length}',
                        label: 'Flashcard Sets',
                        icon: HugeIcons.strokeRoundedFolder01,
                        theme: theme,
                        colorScheme: colorScheme,
                      ),
                    ),
                    const SizedBox(width: 16),
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
        const SizedBox(height: 24),

        // Study Activity Heatmap
        _StudyHeatmapCard(
          userId: _userId!,
          statsService: _statsService,
          theme: theme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 24),

        // Bottom Row: Recent Activity, Weekly Performance, Study Goals
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _RecentActivityCard(
                userId: _userId!,
                statsService: _statsService,
                theme: theme,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _WeeklyPerformanceCard(
                userId: _userId!,
                statsService: _statsService,
                theme: theme,
                colorScheme: colorScheme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
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
              icon: _isOpen ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
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
          color: _isHovered ? widget.colorScheme.onSurface.withAlpha(8) : Colors.transparent,
          child: Row(
            children: [
              HugeIcon(icon: widget.icon, size: 20, color: widget.colorScheme.onSurface.withAlpha(153)),
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
// STREAK CARD (Enhanced)
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
    final isOnFire = currentStreak >= 3;
    final fireColor = isOnFire ? Colors.orange : colorScheme.onSurface.withAlpha(102);

    return Container(
      height: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOnFire ? Colors.orange.withAlpha(100) : colorScheme.outline.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOnFire ? Colors.orange.withAlpha(30) : colorScheme.onSurface.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedFire,
                size: 24,
                color: fireColor,
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: isOnFire ? Colors.orange : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'day streak',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(128),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
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
      height: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 24, color: colorScheme.onSurface.withAlpha(102)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(102),
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
// STUDY HEATMAP CARD
// ============================================================================

class _StudyHeatmapCard extends StatelessWidget {
  final String userId;
  final UserStatsService statsService;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _StudyHeatmapCard({
    required this.userId,
    required this.statsService,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Study Activity',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Less',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(102),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(5, (index) => Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getHeatmapColor(index, isDark),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                  const SizedBox(width: 4),
                  Text(
                    'More',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withAlpha(102),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<DailyStudyData>>(
            stream: statsService.streamDailyStudyData(userId, days: 140), // ~20 weeks
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];

              if (data.isEmpty) {
                return SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'Start studying to see your activity',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withAlpha(102),
                      ),
                    ),
                  ),
                );
              }

              return _buildHeatmapGrid(data, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid(List<DailyStudyData> data, bool isDark) {
    // Organize data into weeks (7 rows for days of week)
    final weeks = <List<DailyStudyData?>>[];
    var currentWeek = <DailyStudyData?>[];

    // Pad the beginning to align with the correct day of week
    if (data.isNotEmpty) {
      final firstDayOfWeek = data.first.date.weekday; // 1=Mon, 7=Sun
      for (int i = 1; i < firstDayOfWeek; i++) {
        currentWeek.add(null);
      }
    }

    for (final day in data) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }

    // Add remaining days
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add(null);
      }
      weeks.add(currentWeek);
    }

    final dayLabels = ['Mon', '', 'Wed', '', 'Fri', '', 'Sun'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        Column(
          children: dayLabels.map((label) => SizedBox(
            height: 14,
            child: label.isNotEmpty
                ? Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: colorScheme.onSurface.withAlpha(102),
                    ),
                  )
                : const SizedBox(),
          )).toList(),
        ),
        const SizedBox(width: 8),
        // Grid
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: weeks.map((week) {
                return Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Column(
                    children: List.generate(7, (dayIndex) {
                      final dayData = dayIndex < week.length ? week[dayIndex] : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Tooltip(
                          message: dayData != null
                              ? '${_formatDate(dayData.date)}\n${dayData.cardsStudied} cards, ${dayData.sessionsCompleted} sessions'
                              : '',
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: dayData != null
                                  ? _getHeatmapColor(dayData.activityLevel, isDark)
                                  : colorScheme.onSurface.withAlpha(10),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getHeatmapColor(int level, bool isDark) {
    if (isDark) {
      switch (level) {
        case 0: return Colors.white.withAlpha(15);
        case 1: return Colors.green.withAlpha(80);
        case 2: return Colors.green.withAlpha(140);
        case 3: return Colors.green.withAlpha(200);
        case 4: return Colors.green;
        default: return Colors.white.withAlpha(15);
      }
    } else {
      switch (level) {
        case 0: return Colors.black.withAlpha(10);
        case 1: return Colors.green.withAlpha(60);
        case 2: return Colors.green.withAlpha(120);
        case 3: return Colors.green.withAlpha(180);
        case 4: return Colors.green.withAlpha(230);
        default: return Colors.black.withAlpha(10);
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<ActivityItem>>(
              stream: statsService.streamRecentActivity(userId, limit: 6),
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
    switch (type) {
      case 'study':
        return Colors.blue;
      case 'quiz':
        return Colors.green;
      case 'created':
        return Colors.purple;
      default:
        return colorScheme.onSurface;
    }
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: typeColor.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: HugeIcon(
                icon: _getIconForType(activity.type),
                size: 14,
                color: typeColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
// WEEKLY PERFORMANCE CARD
// ============================================================================

class _WeeklyPerformanceCard extends StatelessWidget {
  final String userId;
  final UserStatsService statsService;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _WeeklyPerformanceCard({
    required this.userId,
    required this.statsService,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Performance',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<WeeklyPerformance>>(
              stream: statsService.streamWeeklyPerformance(userId, weeks: 8),
              builder: (context, snapshot) {
                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedChartLineData02,
                          size: 32,
                          color: colorScheme.onSurface.withAlpha(60),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete quizzes to see performance',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withAlpha(102),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return _buildBarChart(data, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<WeeklyPerformance> data, bool isDark) {
    final maxCards = data.isEmpty ? 1 : data.map((w) => w.totalCards).reduce((a, b) => a > b ? a : b);
    final normalizedMax = maxCards == 0 ? 1 : maxCards;

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((week) {
              final height = (week.totalCards / normalizedMax).clamp(0.0, 1.0);
              final accuracy = week.accuracy;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Tooltip(
                    message: 'Week of ${_formatWeek(week.weekStart)}\n${week.totalCards} cards\n${accuracy.round()}% accuracy',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (week.totalCards > 0)
                          Text(
                            '${week.totalCards}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: colorScheme.onSurface.withAlpha(128),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: height == 0 ? 0.02 : height,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _getBarColor(accuracy, isDark),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: data.map((week) {
            return Expanded(
              child: Center(
                child: Text(
                  _formatWeekLabel(week.weekStart),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: colorScheme.onSurface.withAlpha(102),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getBarColor(double accuracy, bool isDark) {
    if (accuracy >= 80) return Colors.green.withAlpha(isDark ? 200 : 180);
    if (accuracy >= 60) return Colors.blue.withAlpha(isDark ? 200 : 180);
    if (accuracy >= 40) return Colors.orange.withAlpha(isDark ? 200 : 180);
    return colorScheme.onSurface.withAlpha(isDark ? 80 : 60);
  }

  String _formatWeek(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatWeekLabel(DateTime date) {
    return '${date.month}/${date.day}';
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
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Goals',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _GoalProgress(
            label: 'Daily Cards',
            current: stats.cardsStudiedToday,
            target: stats.dailyGoalCards,
            icon: HugeIcons.strokeRoundedCards01,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 20),
          _GoalProgress(
            label: 'Weekly Sessions',
            current: stats.sessionsThisWeek,
            target: stats.weeklyGoalSessions,
            icon: HugeIcons.strokeRoundedCalendar03,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 20),
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
              size: 16,
              color: isComplete ? Colors.green : colorScheme.onSurface.withAlpha(102),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ),
            Text(
              '$current / $target',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isComplete ? Colors.green : null,
              ),
            ),
            if (isComplete) ...[
              const SizedBox(width: 4),
              HugeIcon(
                icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                size: 14,
                color: Colors.green,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.onSurface.withAlpha(20),
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? Colors.green : colorScheme.primary,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
