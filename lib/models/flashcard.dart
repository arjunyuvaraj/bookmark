class Flashcard {
  final String front;
  final String back;

  Flashcard({
    required this.front,
    required this.back,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'front': front,
      'back': back,
    };
  }
}
