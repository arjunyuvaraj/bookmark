import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const double _buttonRadius = 8.0;

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showHeaderBorder = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
          primary: Color(0xFF0091FF),
          surface: Color(0xFFF7F6F3),
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
                  _buildContentSection(context),
                  _buildResultsSection(context),
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
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: _showHeaderBorder
                    ? const Color(0xFFE3E2DE)
                    : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/app-icon.png', width: 24, height: 24),
                  const SizedBox(width: 16),
                  Text(
                    'bookmark',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF37352F),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'About',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF37352F),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0091FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_buttonRadius),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.inter(
                        fontSize: 15,
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: screenHeight,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'bookmark',
            style: GoogleFonts.inter(
              color: const Color(0xFF37352F),
              fontSize: 96,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                  color: const Color(0xFF787774), fontSize: 24),
              children: [
                const TextSpan(text: 'study '),
                TextSpan(
                  text: 'smarter',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF37352F),
                  ),
                ),
                const TextSpan(text: ', not '),
                TextSpan(
                  text: 'harder',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF37352F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0091FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_buttonRadius),
              ),
            ),
            child: Text(
              'Get Started',
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

  Widget _buildResultsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      color: const Color(0xFFF7F6F3),
      child: Column(
        children: [
          Text(
            'The Results Speak for Themselves',
            style: GoogleFonts.inter(
              color: const Color(0xFF37352F),
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              "Better Grades, Less Stress\nStop second-guessing your study methods. Bookmark's AI identifies key concepts and creates targeted practice materials so you're actually learning, not just memorizing. Students report feeling more prepared and confident going into exams.\n\nHours Back in Your Day\nWhat used to take an entire evening now takes minutes. Generate comprehensive flashcards and quizzes instantly, giving you more time for what matters—whether that's understanding difficult concepts, getting sleep, or actually having a life outside of studying.\n\nStudy That Sticks\nActive recall and spaced repetition aren't just buzzwords—they're proven learning techniques. Bookmark builds these methods directly into your study routine, helping you retain information long-term instead of forgetting it the day after the test.\n\nAlways There When You Need It\nStuck on a homework problem at 2 AM? Need to review before an 8 AM exam? Bookmark is your 24/7 study companion, ready to help whenever inspiration (or panic) strikes.",
              textAlign: TextAlign.left,
              style: GoogleFonts.inter(
                color: const Color(0xFF787774),
                fontSize: 16,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Meet Your AI Study Partner',
            style: GoogleFonts.inter(
              color: const Color(0xFF37352F),
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              'Bookmark transforms how you study by doing the heavy lifting for you. Upload your syllabus, lecture notes, textbooks, or practice problems, and our AI instantly creates personalized study tools tailored to your courses. No more wasting hours making flashcards or wondering what to focus on—Bookmark analyzes your content and builds exactly what you need to succeed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF787774),
                fontSize: 18,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
