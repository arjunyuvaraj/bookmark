import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.chat_outlined,
      selectedIcon: Icons.chat_rounded,
      label: 'Chatbot',
    ),
    _NavItem(
      icon: Icons.library_books_outlined,
      selectedIcon: Icons.library_books_rounded,
      label: 'Library',
    ),
    _NavItem(
      icon: Icons.upload_outlined,
      selectedIcon: Icons.upload_rounded,
      label: 'Quick Upload',
    ),
    _NavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
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
        setState(() => _selectedIndex = index);
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
    final displayName = user?.displayName ?? 'Guest';

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: colorScheme.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Image.asset('assets/app-icon.png', width: 26, height: 26),
                const SizedBox(width: 12),
                Text('bookmark', style: theme.textTheme.titleMedium),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _navItems.length,
              itemBuilder: (context, index) =>
                  _buildNavItem(index, theme, colorScheme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    style: theme.textTheme.bodyMedium,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(6),
          hoverColor: colorScheme.onSurface.withAlpha(13),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withAlpha(20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.selectedIcon : item.icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withAlpha(153),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withAlpha(180),
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
  final IconData selectedIcon;
  final String label;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
