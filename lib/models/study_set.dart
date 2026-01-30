import 'package:bookmark/models/flashcard_model.dart';
import 'package:bookmark/models/quiz_question.dart';

class StudySet {
  final List<Flashcard> flashcards;
  final List<QuizQuestion> quiz;

  StudySet({required this.flashcards, required this.quiz});

  factory StudySet.fromJson(Map<String, dynamic> json) {
    return StudySet(
      flashcards:
          (json['flashcards'] as List<dynamic>?)
              ?.map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quiz:
          (json['quiz'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  SetModel copyWith({
    String? id,
    String? title,
    String? description,
    List<Flashcard>? cards,
    DateTime? dateAdded,
    int? sessions,
    String? fileUrl,
    String? fileName,
    FileType? fileType,
  }) {
    return SetModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      cards: cards ?? this.cards,
      dateAdded: dateAdded ?? this.dateAdded,
      sessions: sessions ?? this.sessions,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flashcards': flashcards.map((e) => e.toJson()).toList(),
      'quiz': quiz.map((e) => e.toJson()).toList(),
    };
  }
}
