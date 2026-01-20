import 'package:bookmark/models/flashcard.dart';
import 'package:bookmark/models/quiz_question.dart';

class StudySet {
  final List<Flashcard> flashcards;
  final List<QuizQuestion> quiz;

  StudySet({
    required this.flashcards,
    required this.quiz,
  });

  factory StudySet.fromJson(Map<String, dynamic> json) {
    return StudySet(
      flashcards: (json['flashcards'] as List<dynamic>?)
              ?.map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quiz: (json['quiz'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flashcards': flashcards.map((e) => e.toJson()).toList(),
      'quiz': quiz.map((e) => e.toJson()).toList(),
    };
  }
}
