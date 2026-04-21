import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/game_session.dart';
import '../../models/student.dart';
import '../../models/quiz.dart';
import '../../services/firebase_service.dart';
import 'dart:developer' as developer;

/// Repository for all game session operations.
/// Handles real-time collaboration via Firestore streams.
class SessionRepository {
  final FirebaseService _firebase;
  final Map<String, StreamSubscription<DocumentSnapshot>> _activeSubscriptions = {};

  SessionRepository(this._firebase);

  bool get isFirebaseAvailable => _firebase.isInitialized;

  /// Subscribe to a session by PIN.
  /// Returns a stream of GameSession objects.
  /// Caller must cancel the subscription when done.
  Stream<GameSession> subscribeToSession(String pin) {
    if (!isFirebaseAvailable) {
      return Stream<GameSession>.error(
        StateError('Firebase is not initialized.'),
      );
    }

    final stream = _firebase
        .getSessionStream(pin)
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('Session not found');
          }

          final data = snapshot.data() as Map<String, dynamic>;

          // Parse quiz
          final quizData = data['quiz'] as Map<String, dynamic>;
          final quiz = Quiz.fromJson(quizData);

          // Parse students
          final studentsData = data['students'] as List<dynamic>? ?? [];
          final students = studentsData
              .map((s) => Student(
                    name: s['name'] as String,
                    score: s['score'] as int? ?? 0,
                    currentAnswer: s['currentAnswer'],
                    isCorrect: s['isCorrect'],
                  ))
              .toList();

          // Extract other fields
          final currentQuestionIndex = data['currentQuestionIndex'] as int? ?? 0;
          // Convert answerCounts keys from Firestore strings to int
          final rawAnswerCounts = data['answerCounts'] as Map<String, dynamic>? ?? {};
          final answerCounts = <int, int>{};
          rawAnswerCounts.forEach((key, value) {
            final intKey = int.tryParse(key.toString()) ?? 0;
            answerCounts[intKey] = (value as num?)?.toInt() ?? 0;
          });
          final gameStarted = data['gameStarted'] as bool? ?? false;
          final gameEnded = data['gameEnded'] as bool? ?? false;
          final timeRemaining = data['timeRemaining'] as int? ?? 0;

          return GameSession(
            pin: pin,
            quiz: quiz,
            students: students,
            currentQuestionIndex: currentQuestionIndex,
            answerCounts: answerCounts,
            gameStarted: gameStarted,
            gameEnded: gameEnded,
            timeRemaining: timeRemaining,
            questionState: data['questionState'] as String?,
            correctAnswer: data['correctAnswer'] as int?,
          );
        })
        .handleError((error) {
          developer.log('Session stream error: $error');
        });

    return stream;
  }

  /// Create a new session (host only)
  Future<void> createSession({
    required String pin,
    required Quiz quiz,
    String? title,
  }) async {
    if (!isFirebaseAvailable) return;

    await _firebase.createSession(
      pin: pin,
      quizJson: quiz.toJson(),
      title: title ?? quiz.title,
    );
  }

  /// Student joins a session
  Future<void> joinSession(String pin, String studentName) async {
    if (!isFirebaseAvailable) return;
    await _firebase.joinSession(pin, studentName);
  }

  /// Check if a PIN exists (for validation before joining)
  Future<bool> validatePin(String pin) async {
    if (!isFirebaseAvailable) {
      return false;
    }
    return await _firebase.pinExists(pin);
  }

  /// Host starts the game
  Future<void> startGame(String pin, int initialTime) async {
    if (!isFirebaseAvailable) return;
    await _firebase.startGame(pin, initialTime);
  }

  /// Host updates timer (broadcast to all students)
  Future<void> updateTimer(String pin, int timeRemaining) async {
    if (!isFirebaseAvailable) return;
    await _firebase.updateTimer(pin, timeRemaining);
  }

  /// Student submits answer
  Future<void> submitAnswer(String pin, String studentName, dynamic answer) async {
    if (!isFirebaseAvailable) return;
    await _firebase.submitAnswer(pin, studentName, answer);
  }

  /// Host reveals correct answer
  Future<void> revealAnswer(String pin, int correctAnswer) async {
    if (!isFirebaseAvailable) return;
    await _firebase.revealAnswer(pin, correctAnswer);
  }

  /// Move to next question or end game
  Future<void> nextQuestion(String pin) async {
    if (!isFirebaseAvailable) return;
    await _firebase.nextQuestion(pin);
  }

  /// Delete a session (cleanup)
  Future<void> deleteSession(String pin) async {
    if (!isFirebaseAvailable) return;
    await _firebase.deleteSession(pin);
  }

  /// Update an individual student's result (score, isCorrect)
  /// Used after question reveal to persist scores.
  Future<void> updateStudentResult(
    String pin,
    String studentName,
    bool isCorrect,
    int points,
  ) async {
    if (!isFirebaseAvailable) return;
    await _firebase.updateStudentResult(pin, studentName, isCorrect, points);
  }

  /// Force cleanup of any active subscriptions
  void dispose() {
    for (final sub in _activeSubscriptions.values) {
      sub.cancel();
    }
    _activeSubscriptions.clear();
  }
}
