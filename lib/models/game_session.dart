import 'quiz.dart';
import 'student.dart';
import 'question.dart';

class GameSession {
  final String pin;
  final Quiz quiz;
  final List<Student> students;
  final int currentQuestionIndex;
  final Map<int, int> answerCounts;
  final bool gameStarted;
  final bool gameEnded;
  final int timeRemaining;
  final String? questionState; // 'answering', 'revealed', 'between', 'ended'
  final int? correctAnswer;

  GameSession({
    required this.pin,
    required this.quiz,
    this.students = const [],
    this.currentQuestionIndex = 0,
    Map<int, int>? answerCounts,
    this.gameStarted = false,
    this.gameEnded = false,
    this.timeRemaining = 0,
    this.questionState,
    this.correctAnswer,
  }) : answerCounts = answerCounts ?? {0: 0, 1: 0, 2: 0, 3: 0};

  GameSession copyWith({
    String? pin,
    Quiz? quiz,
    List<Student>? students,
    int? currentQuestionIndex,
    Map<int, int>? answerCounts,
    bool? gameStarted,
    bool? gameEnded,
    int? timeRemaining,
    String? questionState,
    int? correctAnswer,
  }) {
    return GameSession(
      pin: pin ?? this.pin,
      quiz: quiz ?? this.quiz,
      students: students ?? this.students,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answerCounts: answerCounts ?? this.answerCounts,
      gameStarted: gameStarted ?? this.gameStarted,
      gameEnded: gameEnded ?? this.gameEnded,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      questionState: questionState ?? this.questionState,
      correctAnswer: correctAnswer ?? this.correctAnswer,
    );
  }

  Question get currentQuestion => quiz.questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex >= quiz.questions.length - 1;
  QuestionType get questionType => currentQuestion.type;
  List<Student> get sortedStudents => List.from(students)
    ..sort((a, b) => b.score.compareTo(a.score));
}
