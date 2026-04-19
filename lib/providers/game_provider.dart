import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/quiz.dart';
import '../models/student.dart';
import '../models/game_session.dart';
import '../models/question.dart';
import '../providers/game_state.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/quiz_repository.dart';
import '../services/firebase_service.dart';

class GameProvider extends ChangeNotifier {
  // Repositories
  final SessionRepository _sessionRepo;
  final QuizRepository _quizRepo;

  // Configuration
  final bool _useFirebase;

  // State (immutable)
  GameState _state = GameState.initial();

  // Subscriptions & timers (runtime resources, not state)
  StreamSubscription<GameSession>? _sessionSubscription;
  Timer? _localTimer;
  Timer? _simulationTimer;
  Timer? _mockStudentTimer;

  // Constants
  static final Quiz mockQuiz = Quiz(
    title: "General Knowledge Challenge",
    questions: [
      Question(
        text: "What is the capital of France?",
        type: QuestionType.multipleChoice,
        options: ["Berlin", "Madrid", "Paris", "Rome"],
        correctIndex: 2,
        timeLimit: 30,
        points: 1000,
      ),
      Question(
        text: "Which planet is closest to the Sun?",
        type: QuestionType.multipleChoice,
        options: ["Venus", "Mercury", "Earth", "Mars"],
        correctIndex: 1,
        timeLimit: 20,
        points: 1000,
      ),
      Question(
        text: "What is 12 × 12?",
        type: QuestionType.multipleChoice,
        options: ["124", "144", "132", "148"],
        correctIndex: 1,
        timeLimit: 15,
        points: 1000,
      ),
      Question(
        text: "Who painted the Mona Lisa?",
        type: QuestionType.multipleChoice,
        options: ["Van Gogh", "Picasso", "Da Vinci", "Monet"],
        correctIndex: 2,
        timeLimit: 30,
        points: 1000,
      ),
      Question(
        text: "What language is Flutter written in?",
        type: QuestionType.multipleChoice,
        options: ["Kotlin", "Swift", "JavaScript", "Dart"],
        correctIndex: 3,
        timeLimit: 20,
        points: 1000,
      ),
    ],
  );

  static final List<Student> mockStudents = [
    Student(name: "Alex 🦊", score: 0),
    Student(name: "Sara ⭐", score: 0),
    Student(name: "Karim 🚀", score: 0),
    Student(name: "Lina 🌸", score: 0),
    Student(name: "Omar 🔥", score: 0),
  ];

  GameProvider()
      : _sessionRepo = SessionRepository(FirebaseService()),
        _quizRepo = QuizRepository(FirebaseService()),
        _useFirebase = SessionRepository(FirebaseService()).isFirebaseAvailable {
    debugPrint('GameProvider: Firebase = $_useFirebase');
    loadSavedQuizzes();
  }

  // ====================
  // GETTERS (public API)
  // ====================
  GameSession? get session => _state.session;
  String? get currentPin => _state.pin;
  String? get currentStudentName => _state.currentStudentName;
  bool get isFirebaseConnected => _useFirebase && _sessionRepo.isFirebaseAvailable;
  bool get isGameStarted => _state.isGameStarted;
  bool get isGameEnded => _state.isGameEnded;
  int get timeRemaining => _state.timeRemaining;
  List<Student> get students => _state.students;
  List<Student> get sortedStudents => _state.sortedStudents;
  Quiz get currentQuiz => _state.currentQuiz ?? mockQuiz;
  int get currentQuestionIndex => _state.currentQuestionIndex;
  String? get questionState => _state.questionState;
  int? get correctAnswer => _state.correctAnswer;
  Question? get currentQuestion => _state.currentQuestion;
  List<Quiz> get savedQuizzes => _state.savedQuizzes;

  // ====================
  // PRIVATE HELPERS
  // ====================

  Future<void> loadSavedQuizzes() async {
    final quizzes = await _quizRepo.loadSavedQuizzes();
    final allQuizzes = [mockQuiz, ...quizzes];
    _state = _state.copyWith(savedQuizzes: allQuizzes);
    notifyListeners();
  }

  void _subscribeToSession(String pin) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _sessionRepo.subscribeToSession(pin).listen(
      (session) {
        _state = _state.copyWith(
          session: session,
          currentQuiz: session.quiz,
        );
        notifyListeners();
        _tryStartHostTimerIfNeeded();
      },
      onError: (e) {
        debugPrint('Session subscription error: $e');
      },
    );
  }

  void _createMockSession(Quiz quiz) {
    final pin = _generatePin();
    final session = GameSession(
      pin: pin,
      quiz: quiz,
      students: List.from(mockStudents.map((s) => Student(name: s.name, score: 0))),
    );
    _state = _state.copyWith(
      session: session,
      pin: pin,
      currentQuiz: quiz,
      isHost: true,
    );
    _startMockStudentSimulation();
    notifyListeners();
  }

  void _startMockStudentSimulation() {
    _mockStudentTimer?.cancel();
    final mockNames = List.from(mockStudents.map((s) => s.name));
    int index = 0;

    _mockStudentTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final session = _state.session;
      if (session == null || index >= mockNames.length) {
        timer.cancel();
        return;
      }
      final updatedStudents = List<Student>.from(session.students)
        ..add(Student(name: mockNames[index], score: 0));
      final updatedSession = session.copyWith(students: updatedStudents);
      _state = _state.copyWith(session: updatedSession);
      index++;
      notifyListeners();
    });
  }

  void _startHostTimer() {
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final session = _state.session;
      if (session == null) {
        timer.cancel();
        return;
      }
      final newTime = session.timeRemaining - 1;
      // Broadcast to Firestore
      if (_state.pin != null) {
        try {
          await _sessionRepo.updateTimer(_state.pin!, newTime);
        } catch (e) {
          debugPrint('Failed to update timer: $e');
        }
      }
      // Update local state
      final updatedSession = session.copyWith(timeRemaining: newTime);
      _state = _state.copyWith(session: updatedSession);
      notifyListeners();

      if (newTime <= 0) {
        timer.cancel();
        endQuestion();
      }
    });
  }

  void _tryStartHostTimerIfNeeded() {
    if (!_state.isHost) return;
    if (_localTimer?.isActive == true) return;
    final state = _state.session?.questionState;
    final time = _state.session?.timeRemaining ?? 0;
    if (state == 'answering' && time > 0) {
      _startHostTimer();
    }
  }

  Future<void> endQuestion() async {
    _localTimer?.cancel();
    _simulationTimer?.cancel();

    final session = _state.session;
    final question = _state.currentQuestion;
    if (session != null && question != null) {
      final updatedStudents = session.students.map((student) {
        final isCorrect = question.isAnswerCorrect(student.currentAnswer);
        if (isCorrect) {
          final baseScore = question.points;
          final timeBonus = session.timeRemaining * 10;
          final newScore = (student.score + baseScore + timeBonus).clamp(0, 2000);
          return student.copyWith(score: newScore, isCorrect: true);
        }
        return student.copyWith(isCorrect: false);
      }).toList();

      final updatedSession = session.copyWith(students: updatedStudents);
      _state = _state.copyWith(session: updatedSession);
      notifyListeners();

      // Sync to Firebase if connected
      if (_useFirebase && _state.pin != null) {
        try {
          await _sessionRepo.revealAnswer(_state.pin!, question.correctIndex);
          // Update individual student scores/result via repository
          for (final student in updatedStudents) {
            if (question.isAnswerCorrect(student.currentAnswer)) {
              final points = question.points + (session.timeRemaining * 10);
              await _sessionRepo.updateStudentResult(
                _state.pin!,
                student.name,
                true,
                points,
              );
            }
          }
        } catch (e) {
          debugPrint('Failed to broadcast reveal: $e');
        }
      }
    }

    Future.delayed(const Duration(seconds: 3), () {
      nextQuestion();
    });
    notifyListeners();
  }

  // ====================
  // TEACHER OPERATIONS
  // ====================

  Future<void> createSession() async {
    await createSessionWithQuiz(currentQuiz.questions, title: currentQuiz.title);
  }

  Future<void> createSessionWithQuiz(List<Question> questions, {String? title}) async {
    final quiz = Quiz(title: title ?? 'Custom Quiz', questions: questions);

    if (_useFirebase) {
      final pin = _generatePin();
      await _sessionRepo.createSession(pin: pin, quiz: quiz, title: title);
      _subscribeToSession(pin);
      _state = _state.copyWith(
        pin: pin,
        isHost: true,
        currentQuiz: quiz,
      );
    } else {
      _createMockSession(quiz);
    }
    notifyListeners();
  }

  void startGame() {
    final question = _state.currentQuiz?.questions.isNotEmpty == true
        ? _state.currentQuiz!.questions[_state.currentQuestionIndex]
        : null;

    if (_useFirebase && _state.pin != null && question != null) {
      _sessionRepo.startGame(_state.pin!, question.timeLimit);
    } else if (_state.session != null) {
      final updatedSession = _state.session!.copyWith(gameStarted: true);
      _state = _state.copyWith(session: updatedSession);
      _startQuestion();
    }
    notifyListeners();
  }

  void _startQuestion() {
    final session = _state.session;
    final question = _state.currentQuestion;
    if (session == null || question == null) return;

    final updatedSession = session.copyWith(
      timeRemaining: question.timeLimit,
      answerCounts: {0: 0, 1: 0, 2: 0, 3: 0},
    );
    _state = _state.copyWith(session: updatedSession);

    _localTimer?.cancel();
    _simulationTimer?.cancel();

    if (!_useFirebase) {
      // Mock mode: local countdown timer
      _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentSession = _state.session;
        if (currentSession == null) {
          timer.cancel();
          return;
        }
        final newTime = currentSession.timeRemaining - 1;
        final updated = currentSession.copyWith(timeRemaining: newTime);
        _state = _state.copyWith(session: updated);
        notifyListeners();

        if (newTime <= 0) {
          timer.cancel();
          endQuestion();
        }
      });

      // Bot simulation for mock mode
      _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final currentSession = _state.session;
        if (currentSession == null) return;
        final updatedStudents = currentSession.students.map((student) {
          if (student.currentAnswer != null) return student;
          final isBot = student.name != currentSession.students.first.name;
          if (isBot && currentSession.timeRemaining > 3 && Random().nextDouble() < 0.3) {
            final answer = Random().nextInt(4);
            final isCorrect = answer == question.correctIndex;
            var newScore = student.score;
            if (isCorrect) {
              final baseScore = question.points;
              final timeBonus = currentSession.timeRemaining * 10;
              newScore = (student.score + baseScore + timeBonus).clamp(0, 2000);
            }
            return student.copyWith(
              currentAnswer: answer,
              isCorrect: isCorrect,
              score: newScore,
            );
          }
          return student;
        }).toList();

        // Update answer counts
        final newAnswerCounts = Map<int, int>.from(updatedStudents
            .where((s) => s.currentAnswer != null)
            .fold(<int, int>{}, (map, s) {
          map[s.currentAnswer!] = (map[s.currentAnswer!] ?? 0) + 1;
          return map;
        }));

        final newSession = currentSession.copyWith(
          students: updatedStudents,
          answerCounts: newAnswerCounts,
        );
        _state = _state.copyWith(session: newSession);
        notifyListeners();
      });
    }

    // Reset student answers for the new question (mock mode)
    if (!_useFirebase) {
      final currentSession = _state.session;
      if (currentSession != null) {
        final resetStudents = currentSession.students.map((s) => s.copyWith(
          currentAnswer: null,
          isCorrect: null,
        )).toList();
        _state = _state.copyWith(session: currentSession.copyWith(students: resetStudents));
      }
    }
    // For Firebase, reset handled by Firestore nextQuestion
  }

  void nextQuestion() {
    final pin = _state.pin;
    if (_useFirebase && pin != null) {
      _sessionRepo.nextQuestion(pin);
    } else if (_state.session != null) {
      final session = _state.session!;
      if (session.isLastQuestion) {
        final updated = session.copyWith(gameEnded: true);
        _state = _state.copyWith(session: updated);
        _localTimer?.cancel();
        _simulationTimer?.cancel();
      } else {
        final newIndex = session.currentQuestionIndex + 1;
        final updated = session.copyWith(
          currentQuestionIndex: newIndex,
          timeRemaining: 0,
        );
        _state = _state.copyWith(session: updated);
        _startQuestion();
      }
    }
    notifyListeners();
  }

  void submitStudentAnswer(dynamic answer) {
    final session = _state.session;
    final question = _state.currentQuestion;
    if (session == null || question == null) return;

    if (_useFirebase && _state.currentStudentName != null && _state.pin != null) {
      _sessionRepo.submitAnswer(_state.pin!, _state.currentStudentName!, answer);
    } else {
      // Mock mode: update local state
      if (session.students.isNotEmpty) {
        final student = session.students.first.copyWith(
          currentAnswer: answer,
          isCorrect: question.isAnswerCorrect(answer),
        );
        final updatedStudents = List<Student>.from(session.students);
        if (updatedStudents.isNotEmpty) {
          updatedStudents[0] = student;
        }
        // Update answerCounts only if it's an int (multiple choice)
        final newAnswerCounts = Map<int, int>.from(session.answerCounts);
        if (answer is int) {
          newAnswerCounts[answer] = (newAnswerCounts[answer] ?? 0) + 1;
        }
        final newSession = session.copyWith(
          students: updatedStudents,
          answerCounts: newAnswerCounts,
        );
        _state = _state.copyWith(session: newSession);
        notifyListeners();
      }
    }
  }

  // ====================
  // STUDENT OPERATIONS
  // ====================

  Future<void> studentJoin(String pin, String name) async {
    _state = _state.copyWith(currentStudentName: name);

    if (_useFirebase) {
      await _sessionRepo.joinSession(pin, name);
      _subscribeToSession(pin);
      _state = _state.copyWith(pin: pin);
    } else {
      final session = GameSession(
        pin: pin,
        quiz: mockQuiz,
        students: [Student(name: name, score: 0)],
      );
      _state = _state.copyWith(
        session: session,
        pin: pin,
        currentQuiz: mockQuiz,
      );
      _startMockStudentSimulation();
    }
    notifyListeners();
  }

  Future<bool> validatePin(String pin) async {
    return await _sessionRepo.validatePin(pin);
  }

  Future<void> joinSession(String pin, String name) async {
    await studentJoin(pin, name);
  }

  void setCurrentStudentName(String name) {
    _state = _state.copyWith(currentStudentName: name);
    notifyListeners();
  }

  // ====================
  // QUIZ MANAGEMENT
  // ====================

  Future<void> saveQuiz(String title, List<Question> questions) async {
    final quiz = Quiz(title: title, questions: questions);
    if (_useFirebase) {
      try {
        await _quizRepo.saveQuiz(quiz);
        await loadSavedQuizzes();
      } catch (e) {
        debugPrint('Failed to save quiz to Firebase: $e');
        _state = _state.copyWith(
          savedQuizzes: [..._state.savedQuizzes, quiz],
        );
        notifyListeners();
      }
    } else {
      _state = _state.copyWith(
        savedQuizzes: [..._state.savedQuizzes, quiz],
      );
      notifyListeners();
    }
  }

  Future<void> deleteSavedQuiz(String quizId) async {
    try {
      await _quizRepo.deleteQuiz(quizId);
      await loadSavedQuizzes();
    } catch (e) {
      debugPrint('Failed to delete quiz: $e');
      rethrow;
    }
  }

  Future<void> playQuiz(Quiz quiz) async {
    if (quiz.id != null) {
      try {
        await _quizRepo.incrementPlayCount(quiz.id!);
      } catch (e) {
        debugPrint('Failed to increment play count: $e');
      }
    }
    await createSessionWithQuiz(quiz.questions, title: quiz.title);
  }

  // ====================
  // CLEANUP
  // ====================

  void resetGame() {
    _localTimer?.cancel();
    _simulationTimer?.cancel();
    _mockStudentTimer?.cancel();
    _sessionSubscription?.cancel();
    _state = GameState.initial();
    notifyListeners();
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    _simulationTimer?.cancel();
    _mockStudentTimer?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }

  String _generatePin() {
    const chars = '0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
