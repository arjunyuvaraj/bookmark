import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

const Color _primaryBlue = Color(0xFF2383E2);
const Color _textPrimary = Color(0xFF37352F);
const Color _textSecondary = Color(0xFF787774);
const Color _borderColor = Color(0xFFEBEBE9);

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHero(context),
                    const SizedBox(height: 120),
                    _buildFeatures(context),
                    const SizedBox(height: 120),
                    _buildCTA(context),
                    const SizedBox(height: 80),
                    _buildFooter(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/bookmark-logo.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(_textPrimary, BlendMode.srcIn),
              ),
              const SizedBox(width: 10),
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
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _textPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Get started',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 100, 48, 0),
      child: Column(
        children: [
          Text(
            'bookmark',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _textPrimary,
              fontSize: 72,
              fontWeight: FontWeight.w700,
              letterSpacing: -3,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Upload anything. Get flashcards, quizzes, and an AI tutor instantly.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _textSecondary,
              fontSize: 20,
              height: 1.5,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Get started',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          _FeatureRow(
            title: 'Track your progress',
            description: 'See your study streaks, cards reviewed, quiz accuracy, and daily goals all in one place.',
            imagePath: 'assets/feature-dashboard.png',
            imageOnLeft: true,
          ),
          const SizedBox(height: 100),
          _FeatureRow(
            title: 'AI-generated notes',
            description: 'Upload any content and get clean, organized study notes with key concepts highlighted.',
            imagePath: 'assets/feature-notes.png',
            imageOnLeft: false,
          ),
          const SizedBox(height: 100),
          _FeatureRow(
            title: 'Smart flashcards',
            description: 'Automatically generated flashcards from your notes. Study with spaced repetition.',
            imagePath: 'assets/feature-flashcards.png',
            imageOnLeft: true,
          ),
          const SizedBox(height: 100),
          _FeatureRow(
            title: 'Practice quizzes',
            description: 'Test your knowledge with AI-generated quizzes. Get instant feedback and explanations.',
            imagePath: 'assets/feature-quiz.png',
            imageOnLeft: false,
          ),
          const SizedBox(height: 100),
          _FeatureRow(
            title: 'AI tutor',
            description: 'Ask questions anytime. Get explanations, study tips, and help understanding difficult concepts.',
            imagePath: 'assets/feature-chatbot.png',
            imageOnLeft: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Text(
            'Download bookmark today.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _textPrimary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Get started',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/bookmark-logo.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  _textSecondary.withAlpha(180),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '™',
                style: GoogleFonts.inter(
                  color: _textSecondary.withAlpha(120),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _FooterLink(label: 'Privacy', onTap: () {}),
              const SizedBox(width: 24),
              _FooterLink(label: 'Terms', onTap: () {}),
              const SizedBox(width: 32),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(
                  'Sign in',
                  style: GoogleFonts.inter(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final bool imageOnLeft;

  const _FeatureRow({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.imageOnLeft,
  });

  @override
  Widget build(BuildContext context) {
    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: _textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: GoogleFonts.inter(
            color: _textSecondary,
            fontSize: 18,
            height: 1.6,
          ),
        ),
      ],
    );

    final imageContent = Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 400,
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: _textSecondary.withAlpha(80),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      imagePath.split('/').last,
                      style: GoogleFonts.inter(
                        color: _textSecondary.withAlpha(150),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: imageOnLeft
            ? [
                Expanded(flex: 3, child: imageContent),
                const SizedBox(width: 64),
                Expanded(flex: 2, child: textContent),
              ]
            : [
                Expanded(flex: 2, child: textContent),
                const SizedBox(width: 64),
                Expanded(flex: 3, child: imageContent),
              ],
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: GoogleFonts.inter(
            color: _isHovered ? _textPrimary : _textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
