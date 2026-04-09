import 'package:cloud_firestore/cloud_firestore.dart';
import 'question.dart';

class Quiz {
  final String? id; // Firestore document ID (null for unsaved quizzes)
  final String title;
  final List<Question> questions;
  final DateTime? createdAt;
  final int playCount;
  final double? averageScore;
  final List<String>? tags;

  Quiz({
    this.id,
    required this.title,
    required this.questions,
    this.createdAt,
    this.playCount = 0,
    this.averageScore,
    this.tags,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final questionsList = json['questions'] as List<dynamic>? ?? [];
    return Quiz(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Untitled Quiz',
      questions: questionsList
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      playCount: json['playCount'] as int? ?? 0,
      averageScore:
          (json['averageScore'] as num?)?.toDouble(), // Handles double or int
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'playCount': playCount,
      if (averageScore != null) 'averageScore': averageScore,
      if (tags != null) 'tags': tags,
    };
  }

  /// Create a copy with updated fields (for immutability)
  Quiz copyWith({
    String? id,
    String? title,
    List<Question>? questions,
    DateTime? createdAt,
    int? playCount,
    double? averageScore,
    List<String>? tags,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      playCount: playCount ?? this.playCount,
      averageScore: averageScore ?? this.averageScore,
      tags: tags ?? this.tags,
    );
  }
}
