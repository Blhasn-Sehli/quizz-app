import '../../models/quiz.dart';
import '../../services/firebase_service.dart';
import '../../services/auth_service.dart';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Repository responsible for all quiz persistence operations.
/// Abstracts away Firestore access from business logic.
class QuizRepository {
  final FirebaseService _firebase;
  final AuthService _auth;

  QuizRepository(this._firebase) : _auth = AuthService();

  /// Check if Firebase is available for quiz operations
  bool get isFirebaseAvailable => _firebase.isInitialized;

  /// Save a quiz to persistent storage.
  /// If Firebase is available and teacher is logged in, saves to Firestore.
  Future<void> saveQuiz(Quiz quiz) async {
    final userId = _auth.currentUser?.uid;
    if (isFirebaseAvailable && userId != null) {
      // Convert quiz to JSON list of maps
      final questionsJson = quiz.questions
          .map((q) => q.toJson())
          .toList();
      await _firebase.saveQuizToFirestore(
        quiz.title,
        questionsJson,
      );
      developer.log('Quiz saved to Firestore for user $userId');
    } else {
      developer.log('Quiz not saved: Firebase=${isFirebaseAvailable}, userId=$userId');
      return;
    }
  }

  /// Load all saved quizzes for the currently logged-in teacher.
  /// Returns empty list if no user is logged in or Firebase not initialized.
  Future<List<Quiz>> loadSavedQuizzes() async {
    if (!isFirebaseAvailable) {
      return [];
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      developer.log('loadSavedQuizzes: teacher not logged in, returning empty list.');
      return [];
    }

    try {
      final quizMaps = await _firebase.loadSavedQuizzes();
      return quizMaps
          .map((map) {
            try {
              return Quiz.fromJson({
                'id': map['id'] as String?,        // Firestore document ID
                'title': map['title'] as String? ?? 'Untitled Quiz',
                'questions': map['questions'] as List<dynamic>? ?? [],
                'createdAt': map['createdAt'],      // Firestore Timestamp
                'playCount': map['playCount'] as int? ?? 0,
              });
            } catch (e) {
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
