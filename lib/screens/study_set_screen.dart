// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:bookmark/models/study_set.dart';
// import 'package:bookmark/components/flashcard_view.dart';
// import 'package:bookmark/components/quiz_view.dart';
// import 'package:bookmark/theme/color_scheme.dart' as colors;

// class StudySetScreen extends StatefulWidget {
//   final StudySet studySet;
//   final String? title;

//   const StudySetScreen({
//     super.key,
//     required this.studySet,
//     this.title,
//   });

//   @override
//   State<StudySetScreen> createState() => _StudySetScreenState();
// }

// class _StudySetScreenState extends State<StudySetScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: colors.darkGray,
//       appBar: AppBar(
//         backgroundColor: colors.darkGray,
//         leading: IconButton(
//           icon: Icon(Icons.close, color: colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           widget.title ?? 'Study Set',
//           style: GoogleFonts.instrumentSerif(
//             color: colors.white,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: colors.primaryBlue,
//           labelColor: colors.white,
//           unselectedLabelColor: colors.secondary,
//           tabs: [
//             Tab(
//               icon: const Icon(Icons.style),
//               text: 'Flashcards (${widget.studySet.flashcards.length})',
//             ),
//             Tab(
//               icon: const Icon(Icons.quiz),
//               text: 'Quiz (${widget.studySet.quiz.length})',
//             ),
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: FlashcardView(flashcards: widget.studySet.flashcards),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: QuizView(questions: widget.studySet.quiz),
//           ),
//         ],
//       ),
//     );
//   }
// }
