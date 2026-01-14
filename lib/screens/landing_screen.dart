import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grain/grain.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const Color primaryBlue = Color(0xFF0670A1);
  static const Color darkGray = Color(0xFF202124);
  static const Color white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGray,
      body: Stack(
        children: [
          SingleChildScrollView(
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
          decoration: BoxDecoration(color: darkGray.withValues(alpha: 0.3)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('app-icon.png', width: 24, height: 24),
                  const SizedBox(width: 16),
                  Text(
                    'bookmark',
                    style: GoogleFonts.instrumentSerif(
                      color: white,
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
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
                      style: GoogleFonts.inter(color: white, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return GrainFiltered(
      child: Container(
        width: double.infinity,
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryBlue, Color(0xFF0A3D5C), Color(0xFF202124)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'bookmark',
              style: GoogleFonts.instrumentSerif(
                color: white,
                fontSize: 192,
                fontWeight: FontWeight.w400,
                height: 0.8,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -2),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(color: white, fontSize: 24),
                  children: const [
                    TextSpan(text: 'study '),
                    TextSpan(
                      text: 'smarter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ', not '),
                    TextSpan(
                      text: 'harder',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/app');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGray,
                foregroundColor: white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
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
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return GrainFiltered(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        color: darkGray,
        child: Column(
          children: [
            Text(
              'The Results Speak for Themselves',
              style: GoogleFonts.instrumentSerif(
                color: white,
                fontSize: 64,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Text(
                "Better Grades, Less Stress\nStop second-guessing your study methods. Bookmark's AI identifies key concepts and creates targeted practice materials so you're actually learning, not just memorizing. Students report feeling more prepared and confident going into exams.\nHours Back in Your Day\n What used to take an entire evening now takes minutes. Generate comprehensive flashcards and quizzes instantly, giving you more time for what matters—whether that's understanding difficult concepts, getting sleep, or actually having a life outside of studying. \nStudy That Sticks \nActive recall and spaced repetition aren't just buzzwords—they're proven learning techniques. Bookmark builds these methods directly into your study routine, helping you retain information long-term instead of forgetting it the day after the test. \nAlways There When You Need It \nStuck on a homework problem at 2 AM? Need to review before an 8 AM exam? Bookmark is your 24/7 study companion, ready to help whenever inspiration (or panic) strikes.",
                textAlign: TextAlign.left,
                style: GoogleFonts.inter(
                  color: white,
                  fontSize: 18,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return GrainFiltered(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        color: darkGray,
        child: Column(
          children: [
            Text(
              'Meet Your AI Study Partner',
              style: GoogleFonts.instrumentSerif(
                color: white,
                fontSize: 64,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Text(
                'Bookmark transforms how you study by doing the heavy lifting for you. Upload your syllabus, lecture notes, textbooks, or practice problems, and our AI instantly creates personalized study tools tailored to your courses. No more wasting hours making flashcards or wondering what to focus on—Bookmark analyzes your content and builds exactly what you need to succeed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: white,
                  fontSize: 18,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
