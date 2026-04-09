import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'providers/game_provider.dart';
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

  // Initialize Firebase
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
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) async {
    // Get current auth state
    final authService = AuthService();
    final isLoggedIn = authService.isLoggedIn;
    final isGoingToTeacherRoute = state.matchedLocation.startsWith('/teacher/');
    final isGoingToLoginOrRegister =
        state.matchedLocation == '/teacher/login' ||
        state.matchedLocation == '/teacher/register';

    // If going to a protected teacher route and not logged in, redirect to login
    if (isGoingToTeacherRoute &&
        !isGoingToLoginOrRegister &&
        !isLoggedIn) {
      return '/teacher/login';
    }

    // If logged in and going to login/register, go to quiz creator
    if ((state.matchedLocation == '/teacher/login' ||
        state.matchedLocation == '/teacher/register') && isLoggedIn) {
      return '/teacher/quiz-creator';
    }

    // Otherwise, allow the route
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    // Teacher authentication routes
    GoRoute(
      path: '/teacher/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/teacher/register',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      },
    ),
    // Teacher routes
    GoRoute(
      path: '/teacher/quiz-creator',
      builder: (BuildContext context, GoRouterState state) {
        return const QuizCreatorScreen();
      },
    ),
    GoRoute(
      path: '/teacher/lobby',
      builder: (BuildContext context, GoRouterState state) {
        return const TeacherLobbyScreen();
      },
    ),
    GoRoute(
      path: '/teacher/host',
      builder: (BuildContext context, GoRouterState state) {
        return const HostGameScreen();
      },
    ),
    GoRoute(
      path: '/teacher/leaderboard',
      builder: (BuildContext context, GoRouterState state) {
        return const FinalLeaderboardScreen();
      },
    ),
    GoRoute(
      path: '/teacher/quiz-history',
      builder: (BuildContext context, GoRouterState state) {
        return const QuizHistoryScreen();
      },
    ),
    // Student routes
    GoRoute(
      path: '/student/join',
      builder: (BuildContext context, GoRouterState state) {
        return const JoinScreen();
      },
    ),
    GoRoute(
      path: '/student/lobby',
      builder: (BuildContext context, GoRouterState state) {
        final args = state.extra as Map<String, String>?;
        return StudentLobbyScreen(
          pin: args?['pin'] ?? '',
          name: args?['name'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/student/question',
      builder: (BuildContext context, GoRouterState state) {
        return const QuestionScreen();
      },
    ),
    GoRoute(
      path: '/student/leaderboard',
      builder: (BuildContext context, GoRouterState state) {
        return const StudentLeaderboardScreen();
      },
    ),
  ],
);

class QuizzApp extends StatelessWidget {
  const QuizzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp.router(
        title: 'QuizzApp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D1B2A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF46178F),
            secondary: Color(0xFF1368CE),
            surface: Color(0xFF0D1B2A),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}
