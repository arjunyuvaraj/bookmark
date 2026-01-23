import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const double _buttonRadius = 6.0;
const Color _primaryBlue = Color(0xFF2383E2);
const Color _textPrimary = Color(0xFF37352F);
const Color _textSecondary = Color(0xFF787774);
const Color _surfaceColor = Color(0xFFFBFBFA);
const Color _borderColor = Color(0xFFEBEBE9);

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showHeaderBorder = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShowBorder = _scrollController.offset > 20;
    if (shouldShowBorder != _showHeaderBorder) {
      setState(() {
        _showHeaderBorder = shouldShowBorder;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: _primaryBlue,
          surface: _surfaceColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildHeroSection(context),
                  _buildLogosSection(context),
                  _buildFeatureSection(context),
                  _buildProductShowcase(context),
                  _buildBenefitsSection(context),
                  _buildCTASection(context),
                  _buildFooter(context),
                ],
              ),
            ),
            _buildHeader(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border(
              bottom: BorderSide(
                color: _showHeaderBorder ? _borderColor : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/app-icon.png', width: 28, height: 28),
                  const SizedBox(width: 12),
                  Text(
                    'bookmark',
                    style: GoogleFonts.inter(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _HeaderLink(label: 'Features', onTap: () {}),
                  _HeaderLink(label: 'Pricing', onTap: () {}),
                  _HeaderLink(label: 'About', onTap: () {}),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text(
                      'Log in',
                      style: GoogleFonts.inter(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_buttonRadius),
                      ),
                    ),
                    child: Text(
                      'Get bookmark free',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 140, bottom: 80),
      color: Colors.white,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              Text(
                'One study tool.',
                style: GoogleFonts.inter(
                  color: _textPrimary,
                  fontSize: 76,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -3,
                  height: 1.05,
                ),
              ),
              Text(
                'Zero wasted time.',
                style: GoogleFonts.inter(
                  color: _textPrimary,
                  fontSize: 76,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -3,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Text(
                  'Bookmark is where students upload content and AI creates\npersonalized flashcards, quizzes, and study materials instantly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _textSecondary,
                    fontSize: 20,
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_buttonRadius),
                      ),
                    ),
                    child: Text(
                      'Get bookmark free',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      minimumSize: const Size(0, 48),
                      side: const BorderSide(color: _borderColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_buttonRadius),
                      ),
                    ),
                    child: Text(
                      'Watch demo',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 64),
              // Product mockup placeholder
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 80),
                constraints: const BoxConstraints(maxWidth: 1100),
                height: 600,
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 64, color: _textSecondary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Product Screenshot',
                        style: GoogleFonts.inter(
                          color: _textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogosSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Trusted by students at top universities',
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LogoPlaceholder(name: 'Stanford'),
              _LogoPlaceholder(name: 'MIT'),
              _LogoPlaceholder(name: 'Harvard'),
              _LogoPlaceholder(name: 'Berkeley'),
              _LogoPlaceholder(name: 'Yale'),
              _LogoPlaceholder(name: 'Princeton'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Introducing\nSmart Study',
                      style: GoogleFonts.inter(
                        color: _textPrimary,
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _FeatureListItem(
                      title: 'Upload anything',
                      description: 'PDFs, notes, textbooks, slides—we handle it all.',
                      isActive: true,
                    ),
                    _FeatureListItem(
                      title: 'AI-powered parsing',
                      description: 'Intelligent extraction of key concepts and terms.',
                    ),
                    _FeatureListItem(
                      title: 'Instant flashcards',
                      description: 'Generate study materials in seconds, not hours.',
                    ),
                    _FeatureListItem(
                      title: 'Personalized to you',
                      description: 'Adaptive learning that matches your pace.',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 80),
              Expanded(
                flex: 1,
                child: Container(
                  height: 500,
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_outlined, size: 48, color: _textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('Feature Demo', style: GoogleFonts.inter(color: _textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductShowcase(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      color: _surfaceColor,
      child: Column(
        children: [
          Text(
            'More learning.\nFewer tools.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _textPrimary,
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Replace your flashcard apps, note-taking tools, and quiz makers.\nBookmark does it all.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 18,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See all features',
                  style: GoogleFonts.inter(
                    color: _primaryBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 18, color: _primaryBlue),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Row(
            children: [
              Expanded(child: _ProductCard(
                icon: Icons.style_outlined,
                title: 'Flashcards',
                description: 'AI-generated cards from your content with spaced repetition.',
              )),
              const SizedBox(width: 20),
              Expanded(child: _ProductCard(
                icon: Icons.quiz_outlined,
                title: 'Quizzes',
                description: 'Practice tests that adapt to your knowledge gaps.',
              )),
              const SizedBox(width: 20),
              Expanded(child: _ProductCard(
                icon: Icons.chat_outlined,
                title: 'AI Tutor',
                description: 'Ask questions and get instant explanations 24/7.',
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              height: 450,
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Center(
                child: Icon(Icons.trending_up, size: 64, color: _textSecondary.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(width: 80),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The results speak\nfor themselves.',
                  style: GoogleFonts.inter(
                    color: _textPrimary,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 40),
                _StatItem(value: '2x', label: 'faster study prep'),
                const SizedBox(height: 24),
                _StatItem(value: '85%', label: 'better retention'),
                const SizedBox(height: 24),
                _StatItem(value: '10hrs', label: 'saved per week'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 100),
      color: _surfaceColor,
      child: Column(
        children: [
          Text(
            'Try for free.',
            style: GoogleFonts.inter(
              color: _textPrimary,
              fontSize: 64,
              fontWeight: FontWeight.w700,
              letterSpacing: -2.5,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CTACard(
                icon: Icons.school_outlined,
                title: 'Get started on bookmark',
                description: 'Your AI study partner for better grades.',
                buttonText: 'Start studying free',
                isPrimary: true,
              ),
              const SizedBox(width: 24),
              _CTACard(
                icon: Icons.upload_file_outlined,
                title: 'Import your notes',
                description: 'Upload existing materials to get started instantly.',
                buttonText: 'Upload content',
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/app-icon.png', width: 32, height: 32),
                        const SizedBox(width: 12),
                        Text(
                          'bookmark',
                          style: GoogleFonts.inter(
                            color: _textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _SocialIcon(icon: Icons.camera_alt_outlined),
                        _SocialIcon(icon: Icons.link),
                        _SocialIcon(icon: Icons.alternate_email),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: _FooterColumn(title: 'Product', items: ['Features', 'Pricing', 'Updates'])),
              Expanded(child: _FooterColumn(title: 'Resources', items: ['Help center', 'Blog', 'Guides'])),
              Expanded(child: _FooterColumn(title: 'Company', items: ['About', 'Careers', 'Contact'])),
              Expanded(child: _FooterColumn(title: 'Legal', items: ['Privacy', 'Terms', 'Security'])),
            ],
          ),
          const SizedBox(height: 48),
          Divider(color: _borderColor),
          const SizedBox(height: 24),
          Text(
            '© 2026 Bookmark. All rights reserved.',
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderLink({required this.label, required this.onTap});

  @override
  State<_HeaderLink> createState() => _HeaderLinkState();
}

class _HeaderLinkState extends State<_HeaderLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? _surfaceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  final String name;

  const _LogoPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        name,
        style: GoogleFonts.inter(
          color: _textSecondary.withValues(alpha: 0.6),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _FeatureListItem extends StatelessWidget {
  final String title;
  final String description;
  final bool isActive;

  const _FeatureListItem({
    required this.title,
    required this.description,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _borderColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isActive)
            Container(
              width: 4,
              height: 48,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: isActive ? _textPrimary : _textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: _textSecondary,
                    fontSize: 14,
                    height: 1.5,
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

class _ProductCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ProductCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          boxShadow: _isHovered ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, size: 32, color: _textPrimary),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: GoogleFonts.inter(
                color: _textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(widget.icon, size: 40, color: _textSecondary.withValues(alpha: 0.3)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: _primaryBlue,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            color: _textSecondary,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}

class _CTACard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final bool isPrimary;

  const _CTACard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: _textPrimary),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          isPrimary
              ? ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.apple, size: 18),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_buttonRadius),
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: const BorderSide(color: _borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_buttonRadius),
                    ),
                  ),
                  child: Text(buttonText),
                ),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            item,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 14,
            ),
          ),
        )),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;

  const _SocialIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 18, color: _textSecondary),
    );
  }
}
