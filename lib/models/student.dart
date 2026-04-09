class Student {
  String name;
  int score;
  int? currentAnswer;
  bool? isCorrect;

  Student({
    required this.name,
    this.score = 0,
    this.currentAnswer,
    this.isCorrect,
  });

  void reset() {
    currentAnswer = null;
    isCorrect = null;
  }

  Student copyWith({
    String? name,
    int? score,
    int? currentAnswer,
    bool? isCorrect,
  }) {
    return Student(
      name: name ?? this.name,
      score: score ?? this.score,
      currentAnswer: currentAnswer ?? this.currentAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['name'] as String,
      score: json['score'] as int? ?? 0,
      currentAnswer: json['currentAnswer'] as int?,
      isCorrect: json['isCorrect'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'currentAnswer': currentAnswer,
      'isCorrect': isCorrect,
    };
  }
}
