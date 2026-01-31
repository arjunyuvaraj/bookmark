import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a study note generated from uploaded content
class NoteModel {
  String? id;
  String title;
  String subject;
  String notes; // Markdown-formatted content
  SourceType sourceType;
  DateTime createdAt;
  DateTime updatedAt;

  NoteModel({
    this.id,
    required this.title,
    required this.subject,
    required this.notes,
    this.sourceType = SourceType.text,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'subject': subject,
        'notes': notes,
        'sourceType': sourceType.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory NoteModel.fromJson(Map<String, dynamic> json, {String? id}) =>
      NoteModel(
        id: id,
        title: json['title'] ?? '',
        subject: json['subject'] ?? '',
        notes: json['notes'] ?? '',
        sourceType: SourceType.values.firstWhere(
          (s) => s.name == json['sourceType'],
          orElse: () => SourceType.text,
        ),
        createdAt:
            (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

/// Type of source content the note was generated from
enum SourceType { pdf, image, video, url, text }

/// Quiz question model for practice quizzes generated from notes
class QuizQuestion {
  String question;
  List<String> options;
  int correctAnswer;
  String explanation;
  String difficulty;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.difficulty = 'medium',
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'difficulty': difficulty,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'] ?? '',
        options: List<String>.from(json['options'] ?? []),
        correctAnswer: json['correctAnswer'] ?? 0,
        explanation: json['explanation'] ?? '',
        difficulty: json['difficulty'] ?? 'medium',
      );
}
