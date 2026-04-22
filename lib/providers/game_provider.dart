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
  final SessionRepository _sessionRepo;
  final QuizRepository _quizRepo;
  final bool _useFirebase;

  GameState _state = GameState.initial();

  StreamSubscription<GameSession>? _sessionSubscription;
  Timer? _localTimer;
  Timer? _nextQuestionTimer;
  bool _isDisposed = false;

  static final Quiz emptyQuiz = Quiz(title: 'Quiz', questions: []);

  GameProvider()
      : _sessionRepo = SessionRepository(FirebaseService()),
        _quizRepo = QuizRepository(FirebaseService()),
        _useFirebase = SessionRepository(FirebaseService()).isFirebaseAvailable {
    debugPrint('GameProvider: Firebase = $_useFirebase');
    loadSavedQuizzes();
  }

  // ====================
  // GETTERS
  // ====================
  GameSession? get session => _state.session;
  String? get currentPin => _state.pin;
  String? get currentStudentName => _state.currentStudentName;
  bool get isFirebaseConnected =>
      _useFirebase && _sessionRepo.isFirebaseAvailable;
  bool get isGameStarted => _state.isGameStarted;
  bool get isGameEnded => _state.isGameEnded;
  int get timeRemaining => _state.timeRemaining;
  List<Student> get students => _state.students;
  List<Student> get sortedStudents => _state.sortedStudents;
  Quiz get currentQuiz => _state.currentQuiz ?? emptyQuiz;
  int get currentQuestionIndex => _state.currentQuestionIndex;
  String? get questionState => _state.questionState;
  int? get correctAnswer => _state.correctAnswer;
  Question? get currentQuestion => _state.currentQuestion;
  List<Quiz> get savedQuizzes => _state.savedQuizzes;

  // ====================
  // PRIVATE HELPERS
  // ====================

  Future<void> loadSavedQuizzes() async {
    try {
      final quizzes = await _quizRepo.loadSavedQuizzes();
      if (_isDisposed) return;
      _state = _state.copyWith(savedQuizzes: quizzes);
      _notifyIfActive();
    } catch (e) {
      debugPrint('loadSavedQuizzes failed: $e');
    }
  }

  void _subscribeToSession(String pin) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _sessionRepo.subscribeToSession(pin).listen(
      (session) {
        if (_isDisposed) return;
        _state = _state.copyWith(
          session: session,
          currentQuiz: session.quiz,
        );
        _notifyIfActive();
        _tryStartHostTimerIfNeeded();
      },
      onError: (e) {
        debugPrint('Session subscription error: $e');
      },
    );
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
      if (_state.pin != null) {
        try {
          await _sessionRepo.updateTimer(_state.pin!, newTime);
        } catch (e) {
          debugPrint('Failed to update timer: $e');
        }
      }
      final updatedSession = session.copyWith(timeRemaining: newTime);
      _state = _state.copyWith(session: updatedSession);
      _notifyIfActive();

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
    _nextQuestionTimer?.cancel();

    final session = _state.session;
    final question = _state.currentQuestion;
    if (session != null && question != null) {
      final updatedStudents = session.students.map((student) {
        final isCorrect = question.isAnswerCorrect(student.currentAnswer);
        if (isCorrect) {
          final baseScore = question.points;
          final timeBonus = session.timeRemaining * 10;
          final newScore =
              (student.score + baseScore + timeBonus).clamp(0, 2000);
          return student.copyWith(score: newScore, isCorrect: true);
        }
        return student.copyWith(isCorrect: false);
      }).toList();

      final updatedSession = session.copyWith(students: updatedStudents);
      _state = _state.copyWith(session: updatedSession);
      _notifyIfActive();

      if (_useFirebase && _state.pin != null) {
        try {
          await _sessionRepo.revealAnswer(_state.pin!, question.correctIndex);
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

    // FIX: Was 3 seconds — students were being kicked to leaderboard before
    // they could even read their result. 7 seconds gives them time to see
    // correct/wrong feedback AND the leaderboard transition on their device.
    // The teacher can still manually advance early via "Next Question" button.
    _nextQuestionTimer = Timer(const Duration(seconds: 3000), () {
      if (_isDisposed) return;
      nextQuestion();
    });
    _notifyIfActive();
  }

  // ====================
  // TEACHER OPERATIONS
  // ====================

  Future<void> createSession() async {
    await createSessionWithQuiz(currentQuiz.questions,
        title: currentQuiz.title);
  }

  Future<void> createSessionWithQuiz(List<Question> questions,
      {String? title}) async {
    if (!_useFirebase) {
      debugPrint('createSessionWithQuiz: Firebase is not available.');
      return;
    }

    final quiz = Quiz(title: title ?? 'Custom Quiz', questions: questions);

    _state = GameState.initial().copyWith(
      savedQuizzes: _state.savedQuizzes,
      currentQuiz: quiz,
      isHost: true,
    );
    _notifyIfActive();

    final pin = _generatePin();
    await _sessionRepo.createSession(pin: pin, quiz: quiz, title: title);
    _subscribeToSession(pin);
    _state = _state.copyWith(
      pin: pin,
      isHost: true,
      currentQuiz: quiz,
    );
    _notifyIfActive();
  }

  void startGame() {
    final question = _state.currentQuiz?.questions.isNotEmpty == true
        ? _state.currentQuiz!.questions[_state.currentQuestionIndex]
        : null;

    if (_useFirebase && _state.pin != null && question != null) {
      _sessionRepo.startGame(_state.pin!, question.timeLimit);
    }
    _notifyIfActive();
  }

  void nextQuestion() {
    final pin = _state.pin;
    if (_useFirebase && pin != null) {
      _sessionRepo.nextQuestion(pin);
    }
    _notifyIfActive();
  }

  void submitStudentAnswer(dynamic answer) {
    final session = _state.session;
    final question = _state.currentQuestion;
    if (session == null || question == null) return;

    if (_useFirebase &&
        _state.currentStudentName != null &&
        _state.pin != null) {
      _sessionRepo.submitAnswer(
          _state.pin!, _state.currentStudentName!, answer);
    }
  }

  // ====================
  // STUDENT OPERATIONS
  // ====================

  Future<void> studentJoin(String pin, String name) async {
    _state = GameState.initial().copyWith(
      savedQuizzes: _state.savedQuizzes,
      currentStudentName: name,
    );
    _notifyIfActive();

    if (_useFirebase) {
      await _sessionRepo.joinSession(pin, name);
      _subscribeToSession(pin);
      _state = _state.copyWith(pin: pin);
    } else {
      debugPrint('studentJoin: Firebase is not available.');
      return;
    }
    _notifyIfActive();
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
        _notifyIfActive();
      }
    } else {
      _state = _state.copyWith(
        savedQuizzes: [..._state.savedQuizzes, quiz],
      );
      _notifyIfActive();
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
    _nextQuestionTimer?.cancel();
    _sessionSubscription?.cancel();
    _state = GameState.initial();
    _notifyIfActive();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _localTimer?.cancel();
    _nextQuestionTimer?.cancel();
    _sessionSubscription?.cancel();
    super.dispose();
  }

  void _notifyIfActive() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  String _generatePin() {
    const chars = '0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}