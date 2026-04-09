import '../models/game_session.dart';
import '../models/quiz.dart';
import '../models/student.dart';
import '../models/question.dart';

/// Immutable state class for the entire game.
/// This follows the Redux/Bloc pattern where state is never mutated directly.
/// Instead, all changes create a new instance via copyWith().
class GameState {
  // Session identity
  final String? pin;
  final String? currentStudentName;
  final bool isHost;

  // Session data
  final GameSession? session;
  final Quiz? currentQuiz; // Convenience cache of session.quiz when available
  final List<Quiz> savedQuizzes;

  // Derived getters
  int get currentQuestionIndex => session?.currentQuestionIndex ?? 0;

  Question? get currentQuestion {
    final quiz = currentQuiz ?? session?.quiz;
    if (quiz == null || quiz.questions.isEmpty) return null;
    final idx = currentQuestionIndex;
    if (idx >= quiz.questions.length) return null;
    return quiz.questions[idx];
  }

  int get timeRemaining => session?.timeRemaining ?? 0;
  String? get questionState => session?.questionState;
  int? get correctAnswer => session?.correctAnswer;
  bool get isGameStarted => session?.gameStarted ?? false;
  bool get isGameEnded => session?.gameEnded ?? false;

  List<Student> get students => session?.students ?? [];
  List<Student> get sortedStudents {
    final list = List<Student>.from(students);
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  // Private constructor - use factory methods
  const GameState._({
    this.pin,
    this.currentStudentName,
    this.isHost = false,
    this.session,
    this.currentQuiz,
    this.savedQuizzes = const [],
  });

  /// Initial empty state
  factory GameState.initial() {
    return const GameState._(
      pin: null,
      currentStudentName: null,
      isHost: false,
      session: null,
      currentQuiz: null,
      savedQuizzes: [],
    );
  }

  /// Copy with specific fields changed
  GameState copyWith({
    String? pin,
    String? currentStudentName,
    bool? isHost,
    GameSession? session,
    Quiz? currentQuiz,
    List<Quiz>? savedQuizzes,
  }) {
    return GameState._(
      pin: pin ?? this.pin,
      currentStudentName: currentStudentName ?? this.currentStudentName,
      isHost: isHost ?? this.isHost,
      session: session ?? this.session,
      currentQuiz: currentQuiz ?? this.currentQuiz,
      savedQuizzes: savedQuizzes ?? this.savedQuizzes,
    );
  }

  @override
  String toString() {
    return 'GameState{'
        'pin: $pin, '
        'isHost: $isHost, '
        'studentCount: ${students.length}, '
        'quizTitle: ${currentQuiz?.title ?? session?.quiz.title ?? 'none'}, '
        'questionIndex: $currentQuestionIndex, '
        'gameStarted: $isGameStarted, '
        'gameEnded: $isGameEnded'
        '}';
  }
}
