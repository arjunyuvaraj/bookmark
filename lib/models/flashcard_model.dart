import 'package:cloud_firestore/cloud_firestore.dart';

// ENUMS: Build the basic enums: FileType and Difficulty
enum FileType { video, pdf, csv, none }

enum Difficulty { easy, medium, hard }

// MODEL: Flashcard model
class Flashcard {
  String question;
  String answer;
  List<String> tags;
  Difficulty difficulty;

  Flashcard({
    required this.question,
    required this.answer,
    this.tags = const [],
    this.difficulty = Difficulty.medium,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    'tags': tags,
    'difficulty': difficulty.name,
  };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    question: json['question'] ?? '',
    answer: json['answer'] ?? '',
    tags: List<String>.from(json['tags'] ?? []),
    difficulty: Difficulty.values.firstWhere(
      (d) => d.name == json['difficulty'],
      orElse: () => Difficulty.medium,
    ),
  );
}

class SetModel {
  String? id;
  String title;
  String description;
  FileType fileType;
  String? fileUrl;
  String? fileName;
  DateTime dateAdded;
  int sessions;
  List<Flashcard> cards;

  SetModel({
    this.id,
    required this.title,
    required this.description,
    this.fileType = FileType.none,
    this.fileUrl,
    this.fileName,
    DateTime? dateAdded,
    this.sessions = 0,
    this.cards = const [],
  }) : dateAdded = dateAdded ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'fileType': fileType.name,
    'fileUrl': fileUrl,
    'fileName': fileName,
    'dateAdded': Timestamp.fromDate(dateAdded),
    'sessions': sessions,
    'cards': cards.map((card) => card.toJson()).toList(),
  };

  // FACTORY: Use the factory to get more control over construction thought the passed JSON
  factory SetModel.fromJson(Map<String, dynamic> json, {String? id}) =>
      SetModel(
        id: id,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        fileType: FileType.values.firstWhere(
          (f) => f.name == json['fileType'],
          orElse: () => FileType.none,
        ),
        fileUrl: json['fileUrl'],
        fileName: json['fileName'],
        dateAdded:
            (json['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
        sessions: json['sessions'] ?? 0,
        cards:
            (json['cards'] as List?)
                ?.map((card) => Flashcard.fromJson(card))
                .toList() ??
            [],
      );

  // METHOD: Copy with method for creating modified copies
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
}
