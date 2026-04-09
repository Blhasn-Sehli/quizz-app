enum QuestionType {
  yesNo,
  multipleChoice,
  text,
}

class Question {
  final String text;
  final QuestionType type;
  final List<String>? options; // For multiple choice and yes/no (2 or 4 items)
  final String? correctAnswerText; // For text questions (keyword matching)
  final int correctIndex; // For multiple choice and yes/no (0-3, or 0=Yes/1=No for yesNo)
  final int points;
  final int timeLimit;

  Question({
    required this.text,
    required this.type,
    this.options,
    this.correctAnswerText,
    required this.correctIndex,
    this.points = 1000,
    required this.timeLimit,
  }) {
    // Validation
    if (type == QuestionType.multipleChoice) {
      assert(options != null && options!.length == 4,
          'Multiple choice must have exactly 4 options');
    } else if (type == QuestionType.yesNo) {
      assert(options != null && options!.length == 2,
          'Yes/No must have exactly 2 options (Yes, No)');
    } else if (type == QuestionType.text) {
      assert(correctAnswerText != null && correctAnswerText!.isNotEmpty,
          'Text questions must have a correct answer text');
    }
  }

  // Helper to check if a student's answer is correct
  bool isAnswerCorrect(dynamic studentAnswer) {
    if (studentAnswer == null) return false;

    switch (type) {
      case QuestionType.yesNo:
      case QuestionType.multipleChoice:
        return studentAnswer == correctIndex;
      case QuestionType.text:
        // Keyword matching: case-insensitive, check if any keyword appears
        if (correctAnswerText == null) return false;
        final studentText = studentAnswer.toString().toLowerCase().trim();
        final keywords = correctAnswerText!.toLowerCase().split(',');
        return keywords.any((keyword) =>
            studentText.contains(keyword.trim()));
    }
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['text'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.name == (json['type'] as String?),
        orElse: () => QuestionType.multipleChoice,
      ),
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
      correctAnswerText: json['correctAnswerText'] as String?,
      correctIndex: json['correctIndex'] as int? ?? 0,
      points: json['points'] as int? ?? 1000,
      timeLimit: json['timeLimit'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type.name,
      'options': options,
      'correctAnswerText': correctAnswerText,
      'correctIndex': correctIndex,
      'points': points,
      'timeLimit': timeLimit,
    };
  }
}
