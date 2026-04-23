import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'providers/game_provider.dart';
import 'providers/theme_provider.dart';
import 'constants/app_theme.dart';
import 'routes/app_routes.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/teacher/login_screen.dart';
import 'screens/teacher/register_screen.dart';
import 'screens/teacher/quiz_creator_screen.dart';
import 'screens/teacher/teacher_lobby_screen.dart';
import 'screens/teacher/host_game_screen.dart';
import 'screens/teacher/final_leaderboard_screen.dart';
import 'screens/teacher/quiz_history_screen.dart';
import 'screens/student/join_screen.dart';
import 'screens/student/student_lobby_screen.dart';
import 'screens/student/question_screen.dart';
import 'screens/student/student_leaderboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  debugPrint('Starting Firebase initialization...');
  final firebaseService = FirebaseService();
  try {
    await firebaseService.initialize();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const QuizzApp());
}

final GoRouter _router = GoRouter(
  initialLocation: AppRoutes.home,
  redirect: (BuildContext context, GoRouterState state) async {
    final location = state.matchedLocation;

    final legacyTarget = AppRoutes.legacyRedirects[location];
    if (legacyTarget != null) return legacyTarget;

    final authService = AuthService();
    final isLoggedIn = authService.isLoggedIn;
    final isGoingToProtected = AppRoutes.protectedTeacherRoutes.contains(location);
    final isGoingToAuth = location == AppRoutes.login || location == AppRoutes.register;

    if (isGoingToProtected && !isGoingToAuth && !isLoggedIn) return AppRoutes.login;
    if (isGoingToAuth && isLoggedIn) return AppRoutes.quizCreator;

    return null;
  },
  routes: <RouteBase>[
    GoRoute(path: AppRoutes.home,
        builder: (_, __) => const HomeScreen()),
    GoRoute(path: AppRoutes.login,
        builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen()),
    GoRoute(path: AppRoutes.quizCreator,
        builder: (_, __) => const QuizCreatorScreen()),
    GoRoute(path: AppRoutes.teacherLobby,
        builder: (_, __) => const TeacherLobbyScreen()),
    GoRoute(path: AppRoutes.hostGame,
        builder: (_, __) => const HostGameScreen()),
    GoRoute(path: AppRoutes.teacherLeaderboard,
        builder: (_, __) => const FinalLeaderboardScreen()),
    GoRoute(path: AppRoutes.quizHistory,
        builder: (_, __) => const QuizHistoryScreen()),
    GoRoute(path: AppRoutes.studentJoin,
        builder: (_, __) => const JoinScreen()),
    GoRoute(
      path: AppRoutes.studentLobby,
      builder: (_, state) {
        final args = state.extra as Map<String, String>?;
        final queryPin  = state.uri.queryParameters['pin'];
        final queryName = state.uri.queryParameters['name'];
        return StudentLobbyScreen(
          pin:  queryPin  ?? args?['pin']  ?? '',
          name: queryName ?? args?['name'] ?? '',
        );
      },
    ),
    GoRoute(path: AppRoutes.studentQuestion,
        builder: (_, __) => const QuestionScreen()),
    GoRoute(path: AppRoutes.studentLeaderboard,
        builder: (_, __) => const StudentLeaderboardScreen()),
  ],
);

class QuizzApp extends StatelessWidget {
  const QuizzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) {
          return MaterialApp.router(
            title: 'QuizzApp',
            debugShowCheckedModeBanner: false,
            // Smooth animated theme switch — 300 ms on all properties
            themeAnimationDuration: const Duration(milliseconds: 300),
            themeAnimationCurve: Curves.easeInOut,
            theme:      AppTheme.light,
            darkTheme:  AppTheme.dark,
            themeMode:  themeProvider.mode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
