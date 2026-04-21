class AppRoutes {
  static const String home = '/';

  // Auth
  static const String login = '/login';
  static const String register = '/register';

  // Teacher
  static const String quizCreator = '/quiz-creator';
  static const String quizHistory = '/quiz-history';
  static const String teacherLobby = '/teacher-lobby';
  static const String hostGame = '/host-game';
  static const String teacherLeaderboard = '/teacher-leaderboard';

  // Student
  static const String studentJoin = '/join';
  static const String studentLobby = '/student-lobby';
  static const String studentQuestion = '/question';
  static const String studentLeaderboard = '/student-leaderboard';

  // Backward-compatible legacy paths
  static const Map<String, String> legacyRedirects = {
    '/teacher/login': login,
    '/teacher/register': register,
    '/teacher/quiz-creator': quizCreator,
    '/teacher/quiz-history': quizHistory,
    '/teacher/lobby': teacherLobby,
    '/teacher/host': hostGame,
    '/teacher/leaderboard': teacherLeaderboard,
    '/student/join': studentJoin,
    '/student/lobby': studentLobby,
    '/student/question': studentQuestion,
    '/student/leaderboard': studentLeaderboard,
  };

  static const Set<String> protectedTeacherRoutes = {
    quizCreator,
    quizHistory,
    teacherLobby,
    hostGame,
    teacherLeaderboard,
  };
}
