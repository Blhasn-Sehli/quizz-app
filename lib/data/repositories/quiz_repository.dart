import '../../models/quiz.dart';
import '../../services/firebase_service.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository responsible for all quiz persistence operations.
/// Abstracts away the data source (Firestore, local storage, mock) from business logic.
class QuizRepository {
  final FirebaseService _firebase;

  QuizRepository(this._firebase);

  /// Check if Firebase is available for quiz operations
  bool get isFirebaseAvailable => _firebase.isInitialized;

  /// Save a quiz to persistent storage.
  /// If Firebase is available, saves to Firestore with metadata.
  /// Otherwise, keeps in memory (or could use local storage in future).
  Future<void> saveQuiz(Quiz quiz, {String? userId}) async {
    if (isFirebaseAvailable && userId != null) {
      // Convert quiz to JSON list of maps
      final questionsJson = quiz.questions
          .map((q) => q.toJson())
          .toList();
      await _firebase.saveQuizToFirestore(
        quiz.title,
        questionsJson,
      );
    } else {
      // In mock mode, just return (the provider will cache in memory)
      // Could implement local storage here later
      return;
    }
  }

  /// Load all saved quizzes from persistent storage.
  /// Returns empty list if none available or Firebase not initialized.
  Future<List<Quiz>> loadSavedQuizzes() async {
    if (!isFirebaseAvailable) {
      return [];
    }

    try {
      final quizMaps = await _firebase.loadSavedQuizzes();
      return quizMaps
          .map((map) {
            try {
              return Quiz.fromJson({
                'title': map['title'] as String? ?? 'Untitled Quiz',
                'questions': map['questions'] as List<dynamic>? ?? [],
                // Include metadata fields if present in future
              });
            } catch (e) {
              // Skip invalid quiz data
              developer.log('Failed to parse quiz: $e');
              return null;
            }
          })
          .whereType<Quiz>()
          .toList();
    } catch (e) {
      developer.log('Error loading saved quizzes: $e');
      return [];
    }
  }

  /// Load a specific quiz by ID (Firestore document ID)
  Future<Quiz?> getQuizById(String id) async {
    if (!isFirebaseAvailable) return null;

    try {
      final snapshot = await _firebase
          .firestore
          .collection('quizzes')
          .doc(id)
          .get();

      if (!snapshot.exists) return null;

      final data = snapshot.data()!;
      return Quiz.fromJson({
        'title': data['title'] as String? ?? 'Untitled Quiz',
        'questions': data['questions'] as List<dynamic>? ?? [],
      });
    } catch (e) {
      developer.log('Error loading quiz by ID: $e');
      return null;
    }
  }

  /// Delete a saved quiz by ID
  Future<void> deleteQuiz(String id) async {
    if (isFirebaseAvailable) {
      await _firebase.deleteSavedQuiz(id);
    }
  }

  /// Update quiz play count (increments counter)
  Future<void> incrementPlayCount(String id) async {
    if (!isFirebaseAvailable) return;

    try {
      await _firebase
          .firestore
          .collection('quizzes')
          .doc(id)
          .update({'playCount': FieldValue.increment(1)});
    } catch (e) {
      developer.log('Failed to increment play count: $e');
    }
  }
}
