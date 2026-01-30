import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:bookmark/theme/color_scheme.dart';

import 'home_screen.dart';
import 'library_screen.dart';
import 'upload_screen.dart';
import 'settings_screen.dart';
import 'chatbot_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _previousIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: HugeIcons.strokeRoundedHome01,
      label: 'Home',
    ),
    _NavItem(
      icon: HugeIcons.strokeRoundedBubbleChat,
      label: 'Chatbot',
    ),
    _NavItem(
      icon: HugeIcons.strokeRoundedLibrary,
      label: 'Library',
    ),
    _NavItem(
      icon: HugeIcons.strokeRoundedCloudUpload,
      label: 'Quick Upload',
    ),
    _NavItem(
      icon: HugeIcons.strokeRoundedUser,
      label: 'Account',
    ),
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatbotScreen(),
    const LibraryScreen(),
    const UploadScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.02, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() => _previousIndex = _selectedIndex);
      _animationController.reverse().then((_) {
        setState(() => _selectedIndex = index);
        // Update slide direction based on navigation direction
        final goingDown = index > _previousIndex;
        _slideAnimation = Tween<Offset>(
          begin: Offset(0, goingDown ? 0.02 : -0.02),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
        );
        _animationController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          _buildSidebar(theme, colorScheme),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'Guest';
    final borderColor = isDark ? darkBorder : lightBorder;
    final logoColor = isDark ? darkTextPrimary : lightTextPrimary;
    final subtitleColor = isDark ? darkTextSecondary : lightTextSecondary;

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/bookmark-logo.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(logoColor, BlendMode.srcIn),
                ),
                const SizedBox(width: 10),
                Text(
                  'bookmark',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) =>
                  _buildNavItem(index, theme, colorScheme),
            ),
          ),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? darkSurface : lightSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      color: subtitleColor,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;
    final item = _navItems[index];

    // Notion-style colors - no blue, just subtle background and text weight change
    final selectedBgColor = isDark ? darkSurface : lightSurface;
    final textColor = isSelected
        ? colorScheme.onSurface
        : colorScheme.onSurface.withAlpha(153);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(6),
          hoverColor: colorScheme.onSurface.withAlpha(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? selectedBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: item.icon,
                  color: textColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
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

class _NavItem {
  final dynamic icon;
  final String label;

  _NavItem({
    required this.icon,
    required this.label,
  });
}
