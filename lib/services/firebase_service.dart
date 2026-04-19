import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  User? _currentUser;

  bool get isInitialized => _auth != null && _firestore != null;
  String? get currentUserId => _currentUser?.uid;

  // Initialize Firebase
  Future<void> initialize() async {
    if (isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: FirebaseOptionsGenerator.currentPlatform,
      );
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      // Don't sign in anonymously - let users choose their auth method
      developer.log('Firebase initialized successfully');
    } catch (e) {
      developer.log('Firebase initialization failed: $e');
      rethrow;
    }
  }

  // Get Firestore instance
  FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _firestore!;
  }

  // ====================
  // SESSION OPERATIONS
  // ====================

  // Create a new session (PIN is document ID)
  Future<void> createSession({
    required String pin,
    required Map<String, dynamic> quizJson,
    String? title,
  }) async {
    final sessionData = {
      'pin': pin,
      'title': title ?? 'Untitled Quiz',
      'quiz': quizJson,
      'students': [],
      'currentQuestionIndex': 0,
      'answerCounts': {},
      'gameStarted': false,
      'gameEnded': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await firestore
        .collection('sessions')
        .doc(pin)
        .set(sessionData);
  }

  // Get a stream of session data by PIN
  Stream<DocumentSnapshot> getSessionStream(String pin) {
    return firestore
        .collection('sessions')
        .doc(pin)
        .snapshots();
  }

  // Join session (add student)
  Future<void> joinSession(String pin, String studentName) async {
    final sessionRef = firestore.collection('sessions').doc(pin);

    // Check if student already exists (case-insensitive)
    final snapshot = await sessionRef.get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final students = List<Map<String, dynamic>>.from(data['students'] ?? []);

      final existingIndex = students.indexWhere(
        (s) => (s['name'] as String).toLowerCase() == studentName.toLowerCase(),
      );

      if (existingIndex == -1) {
        // Add new student
        students.add({
          'name': studentName,
          'score': 0,
          'currentAnswer': null,
          'isCorrect': null,
        });

        await sessionRef.update({'students': students});
      }
    } else {
      throw Exception('Session not found with PIN: $pin');
    }
  }

  // Submit answer
  Future<void> submitAnswer(String pin, String studentName, dynamic answer) async {
    final sessionRef = firestore.collection('sessions').doc(pin);

    final snapshot = await sessionRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final students = List<Map<String, dynamic>>.from(data['students'] ?? []);

    final studentIndex = students.indexWhere(
      (s) => (s['name'] as String).toLowerCase() == studentName.toLowerCase(),
    );

    if (studentIndex != -1) {
      students[studentIndex]['currentAnswer'] = answer;
      // isCorrect will be calculated after question ends

      // Update answerCounts atomically ONLY if answer is an int (for multiple choice statistics)
      if (answer is int) {
        await sessionRef.update({
          'students': students,
          'answerCounts.$answer': FieldValue.increment(1),
        });
      } else {
        await sessionRef.update({
          'students': students,
        });
      }
    }
  }

  // Update student correctness and score (call after question ends)
  Future<void> updateStudentResult(
    String pin,
    String studentName,
    bool isCorrect,
    int points,
  ) async {
    final sessionRef = firestore.collection('sessions').doc(pin);

    final snapshot = await sessionRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final students = List<Map<String, dynamic>>.from(data['students'] ?? []);

    final studentIndex = students.indexWhere(
      (s) => (s['name'] as String).toLowerCase() == studentName.toLowerCase(),
    );

    if (studentIndex != -1) {
      students[studentIndex]['isCorrect'] = isCorrect;
      final currentScore = students[studentIndex]['score'] as int;
      students[studentIndex]['score'] = currentScore + points;

      await sessionRef.update({'students': students});
    }
  }

  // Start game
  Future<void> startGame(String pin, int initialTime) async {
    await firestore
        .collection('sessions')
        .doc(pin)
        .update({
          'gameStarted': true,
          'timeRemaining': initialTime,
          'questionState': 'answering', // 'answering', 'revealed', 'between'
          'correctAnswer': null,
        });
  }

  // Update timer (called by host each second)
  Future<void> updateTimer(String pin, int timeRemaining) async {
    await firestore
        .collection('sessions')
        .doc(pin)
        .update({'timeRemaining': timeRemaining});
  }

  // Reveal correct answer
  Future<void> revealAnswer(String pin, int correctAnswer) async {
    await firestore
        .collection('sessions')
        .doc(pin)
        .update({
          'questionState': 'revealed',
          'correctAnswer': correctAnswer,
        });
  }

  // Move to next question
  Future<void> nextQuestion(String pin) async {
    final sessionRef = firestore.collection('sessions').doc(pin);

    final snapshot = await sessionRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final currentIndex = data['currentQuestionIndex'] as int;
    final quizData = data['quiz'] as Map<String, dynamic>;
    final questionsLength = quizData['questions'].length;

    if (currentIndex >= questionsLength - 1) {
      // Last question, end game
      await sessionRef.update({
        'gameEnded': true,
        'questionState': 'ended',
      });
    } else {
      final newIndex = currentIndex + 1;
      final questions = quizData['questions'] as List;
      final nextQuestionData = questions[newIndex] as Map<String, dynamic>;
      final nextTimeLimit = nextQuestionData['timeLimit'] as int;

      // Reset student answers for new question
      final students = List<Map<String, dynamic>>.from(data['students'] ?? []);
      for (var student in students) {
        student['currentAnswer'] = null;
        student['isCorrect'] = null;
      }

      await sessionRef.update({
        'currentQuestionIndex': newIndex,
        'timeRemaining': nextTimeLimit,
        'questionState': 'answering',
        'answerCounts': {},
        'correctAnswer': null,
        'students': students,
      });
    }
  }

  // Update answer counts (teacher tracks how many chose each option)
  Future<void> updateAnswerCounts(
    String pin,
    Map<int, int> answerCounts,
  ) async {
    await firestore
        .collection('sessions')
        .doc(pin)
        .update({'answerCounts': answerCounts});
  }

  // Check if PIN exists
  Future<bool> pinExists(String pin) async {
    final doc = await firestore.collection('sessions').doc(pin).get();
    return doc.exists;
  }

  // Delete session (cleanup)
  Future<void> deleteSession(String pin) async {
    await firestore.collection('sessions').doc(pin).delete();
  }

  // ====================
  // QUIZ PERSISTENCE
  // ====================

  Future<void> saveQuizToFirestore(String title, List<Map<String, dynamic>> questions) async {
    final user = _auth?.currentUser;
    if (user == null) {
      developer.log('saveQuizToFirestore: no authenticated user, skipping save.');
      return;
    }

    final quizData = {
      'title': title,
      'questions': questions,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'playCount': 0,
    };

    await firestore
        .collection('quizzes')
        .add(quizData);

    developer.log('Quiz "$title" saved for user ${user.uid}');
  }

  Future<List<Map<String, dynamic>>> loadSavedQuizzes() async {
    final user = _auth?.currentUser;
    if (user == null) {
      developer.log('loadSavedQuizzes: no authenticated user.');
      return [];
    }

    try {
      // Requires a composite index on (userId ASC, createdAt DESC).
      // If the index is missing, Firebase will throw and we fall back below.
      final snapshot = await firestore
          .collection('quizzes')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      developer.log('Loaded ${snapshot.docs.length} quizzes for user ${user.uid}');
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      // Fallback: load without ordering (no composite index needed)
      developer.log(
        'loadSavedQuizzes: ordered query failed ($e). '
        'Create index in Firebase Console or deploy firestore.indexes.json. '
        'Falling back to unordered query.',
      );
      try {
        final snapshot = await firestore
            .collection('quizzes')
            .where('userId', isEqualTo: user.uid)
            .get();

        developer.log('Fallback loaded ${snapshot.docs.length} quizzes (unordered)');
        return snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      } catch (e2) {
        developer.log('loadSavedQuizzes fallback also failed: $e2');
        return [];
      }
    }
  }

  Future<void> deleteSavedQuiz(String quizId) async {
    await firestore.collection('quizzes').doc(quizId).delete();
  }
}
