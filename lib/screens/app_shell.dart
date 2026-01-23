import 'package:bookmark/screens/new_set_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'library_screen.dart';
import 'upload_screen.dart';
import 'settings_screen.dart';
import 'chatbot_screen.dart';

const double _sidebarRadius = 8.0;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.chat_rounded, label: 'Chatbot'),
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.library_books_rounded, label: 'Library'),
    _NavItem(icon: Icons.upload_rounded, label: 'Quick Upload'),
    _NavItem(icon: Icons.person, label: 'Account'),
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    const ChatbotScreen(),
    const DashboardScreen(),
    const LibraryScreen(),
    const UploadScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
      _animationController.reverse().then((_) {
        setState(() {
          _selectedIndex = index;
        });
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme, ColorScheme colorScheme) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? 'User';
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 200,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(_sidebarRadius),
        border: Border.all(
          color: colorScheme.outline.withAlpha(isDark ? 255 : 51),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                return _buildNavItem(index, theme, colorScheme);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withAlpha(isDark ? 255 : 102),
                    borderRadius: BorderRadius.circular(_sidebarRadius),
                  ),
                  child: Icon(
                    Icons.person,
                    color: colorScheme.onSurface,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.bodySmall,
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
    final isSelected = _selectedIndex == index;
    final item = _navItems[index];
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(_sidebarRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? colorScheme.outline
                      : colorScheme.primary.withAlpha(26))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(_sidebarRadius),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? (isDark ? colorScheme.onSurface : colorScheme.primary)
                      : colorScheme.onSurface.withAlpha(153),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  item.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? (isDark
                            ? colorScheme.onSurface
                            : colorScheme.primary)
                        : colorScheme.onSurface.withAlpha(153),
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
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}
