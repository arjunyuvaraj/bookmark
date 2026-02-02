import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/screens/flashcard_setting_screen.dart';
import 'package:bookmark/screens/test_screen.dart';
import 'package:bookmark/services/flashcard_service.dart';
import 'package:bookmark/services/user_stats_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum StudyMode { flashcards, test }

class FlashcardPracticeScreen extends StatefulWidget {
  final SetModel set;

  const FlashcardPracticeScreen({super.key, required this.set});

  @override
  State<FlashcardPracticeScreen> createState() =>
      _FlashcardPracticeScreenState();
}

class _FlashcardPracticeScreenState extends State<FlashcardPracticeScreen>
    with TickerProviderStateMixin {
  int currentIndex = 0;
  bool isFlipped = false;
  StudyMode currentMode = StudyMode.flashcards;
  bool isMenuOpen = false;
  bool showCongrats = false;
  bool hasIncrementedSession = false;

  late AnimationController _flipController;
  late AnimationController _progressController;
  late AnimationController _menuController;
  late Animation<double> _flipAnimation;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _menuSlideAnimation;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _menuSlideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _menuController, curve: Curves.easeOut));

    // Initialize progress (guard against empty cards)
    if (widget.set.cards.isNotEmpty) {
      _updateProgress((currentIndex + 1) / widget.set.cards.length);
    }

    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _flipController.dispose();
    _progressController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  void _updateProgress(double target) {
    _progressAnimation =
        Tween<double>(begin: _progressAnimation.value, end: target).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
        );
    _progressController.forward(from: 0);
  }

  void _flipCard() {
    if (isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      isFlipped = !isFlipped;
    });
  }

  Future<void> _incrementSessionCount() async {
    if (!hasIncrementedSession && widget.set.id != null) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FlashcardSetService().incrementSessions(userId, widget.set.id!);

        // Record study session in stats
        await UserStatsService().recordStudySession(
          userId: userId,
          setId: widget.set.id!,
          setTitle: widget.set.title,
          cardsStudied: widget.set.cards.length,
        );

        setState(() {
          hasIncrementedSession = true;
        });
      }
    }
  }

  void _nextCard() {
    if (currentIndex < widget.set.cards.length - 1) {
      setState(() {
        currentIndex++;
        isFlipped = false;
        _flipController.reset();
        _updateProgress((currentIndex + 1) / widget.set.cards.length);
      });
    } else {
      // User finished all cards, show congrats screen
      _incrementSessionCount();
      setState(() {
        showCongrats = true;
      });
    }
  }

  void _previousCard() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        isFlipped = false;
        _flipController.reset();
        _updateProgress((currentIndex + 1) / widget.set.cards.length);
      });
    }
  }

  void _toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
    if (isMenuOpen) {
      _menuController.forward();
    } else {
      _menuController.reverse();
    }
  }

  void _changeMode(StudyMode mode) {
    if (mode == StudyMode.test) {
      _menuController.reverse();
      setState(() {
        isMenuOpen = false;
      });
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TestScreen(set: widget.set)),
      );
    } else {
      setState(() {
        currentMode = mode;
        isMenuOpen = false;
      });
      _menuController.reverse();
    }
  }

  void _openSettings() {
    _menuController.reverse();
    setState(() {
      isMenuOpen = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardSettingScreen(set: widget.set),
      ),
    );
  }

  void _restartStudySession() {
    setState(() {
      currentIndex = 0;
      isFlipped = false;
      showCongrats = false;
      hasIncrementedSession = false;
      _flipController.reset();
      _updateProgress(1 / widget.set.cards.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.set.cards;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    // Handle empty cards case
    if (cards.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
          ),
          title: Text(
            widget.set.title,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.style_outlined,
                size: 64,
                color: colors.onSurface.withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                'No flashcards available',
                style: TextStyle(
                  color: colors.onSurface.withAlpha(150),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && !showCongrats) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _nextCard();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _previousCard();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.space) {
            _flipCard();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: showCongrats
                      ? _buildCongratsScreen(context)
                      : _buildMainContent(context, cards),
                ),
              ],
            ),
            if (isMenuOpen)
              GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withAlpha(isDark ? 128 : 77),
                ),
              ),
            _buildMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCongratsScreen(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration_outlined,
                size: 80,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Congratulations!',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You\'ve completed all ${widget.set.cards.length} flashcards!',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: colors.onSurface.withAlpha(180),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _restartStudySession,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Study Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Back to Library'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: colors.outline.withAlpha(128)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cards = widget.set.cards;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withAlpha(230),
        border: Border(
          bottom: BorderSide(color: colors.outline.withAlpha(128), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: colors.onSurface,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.set.title,
                          style: GoogleFonts.inter(
                            color: colors.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          showCongrats
                              ? 'Completed!'
                              : '${currentIndex + 1} of ${cards.length} cards',
                          style: GoogleFonts.inter(
                            color: colors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!showCongrats)
                    IconButton(
                      onPressed: _toggleMenu,
                      icon: Icon(
                        Icons.more_vert,
                        color: colors.onSurface,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
            // Animated Progress bar
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: showCongrats ? 1.0 : _progressAnimation.value,
                      backgroundColor: colors.outline.withAlpha(77),
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      minHeight: 4,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, List<Flashcard> cards) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 20),
        // Flashcard
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GestureDetector(
                onTap: _flipCard,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * 3.14159;
                    final isFrontVisible = angle < 3.14159 / 2;

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 600,
                          maxHeight: 500,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? colors.surface : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.outline.withAlpha(128),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 77 : 20),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..rotateY(isFrontVisible ? 0 : 3.14159),
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.all(48.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isFrontVisible
                                            ? cards[currentIndex].question
                                            : cards[currentIndex].answer,
                                        style: GoogleFonts.inter(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w600,
                                          color: colors.onSurface,
                                          height: 1.4,
                                          letterSpacing: -0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 20,
                              right: 20,
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..rotateY(isFrontVisible ? 0 : 3.14159),
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isFrontVisible
                                        ? colors.primary.withAlpha(26)
                                        : Colors.green.withAlpha(26),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isFrontVisible ? 'Question' : 'Answer',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isFrontVisible
                                          ? colors.primary
                                          : Colors.green[700],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 24,
                              left: 0,
                              right: 0,
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..rotateY(isFrontVisible ? 0 : 3.14159),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.touch_app_outlined,
                                      size: 16,
                                      color: colors.secondary.withAlpha(153),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Tap to flip',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: colors.secondary.withAlpha(153),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Navigation controls
        Container(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavigationButton(
                icon: Icons.arrow_back_ios_new,
                onPressed: currentIndex > 0 ? _previousCard : null,
                label: 'Previous',
              ),
              const SizedBox(width: 16),
              _NavigationButton(
                icon: Icons.arrow_forward_ios,
                onPressed: _nextCard,
                label: currentIndex < cards.length - 1 ? 'Next' : 'Finish',
                isPrimary: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMenu(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: _menuSlideAnimation,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 280,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? colors.surface : Colors.white,
            border: Border(
              left: BorderSide(color: colors.outline.withAlpha(128), width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 102 : 26),
                blurRadius: 20,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.view_module_outlined,
                        color: colors.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Study Options',
                        style: GoogleFonts.inter(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: colors.outline.withAlpha(77), height: 1),
                const SizedBox(height: 8),
                _MenuItem(
                  icon: Icons.style_outlined,
                  label: 'Flashcards',
                  isSelected: currentMode == StudyMode.flashcards,
                  onTap: () => _changeMode(StudyMode.flashcards),
                ),
                _MenuItem(
                  icon: Icons.quiz_outlined,
                  label: 'Test',
                  isSelected: currentMode == StudyMode.test,
                  onTap: () => _changeMode(StudyMode.test),
                ),
                const SizedBox(height: 8),
                Divider(color: colors.outline.withAlpha(77), height: 1),
                const SizedBox(height: 8),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Manage Cards',
                  isSelected: false,
                  onTap: _openSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withAlpha(20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colors.primary
                    : colors.onSurface.withAlpha(153),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? colors.primary
                      : colors.onSurface.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String label;
  final bool isPrimary;

  const _NavigationButton({
    required this.icon,
    required this.onPressed,
    required this.label,
    this.isPrimary = false,
  });

  @override
  State<_NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<_NavigationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: 18),
          label: Text(widget.label),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isPrimary
                ? (isEnabled ? colors.primary : colors.outline.withAlpha(128))
                : (isEnabled
                      ? (isDark ? colors.surface : Colors.white)
                      : (isDark
                            ? colors.surface.withAlpha(128)
                            : const Color(0xFFFBFBFA))),
            foregroundColor: widget.isPrimary
                ? colors.onPrimary
                : (isEnabled ? colors.onSurface : colors.secondary),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: widget.isPrimary
                  ? BorderSide.none
                  : BorderSide(
                      color: isEnabled
                          ? colors.outline.withAlpha(128)
                          : colors.outline.withAlpha(64),
                    ),
            ),
            shadowColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
