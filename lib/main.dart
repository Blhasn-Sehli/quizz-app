import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'providers/game_provider.dart';
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
  initialLocation: AppRoutes.home,
  redirect: (BuildContext context, GoRouterState state) async {
    final location = state.matchedLocation;

    // Legacy route compatibility.
    final legacyTarget = AppRoutes.legacyRedirects[location];
    if (legacyTarget != null) {
      return legacyTarget;
    }

    // Get current auth state
    final authService = AuthService();
    final isLoggedIn = authService.isLoggedIn;
    final isGoingToProtectedTeacherRoute =
        AppRoutes.protectedTeacherRoutes.contains(location);
    final isGoingToLoginOrRegister =
        location == AppRoutes.login || location == AppRoutes.register;

    // If going to a protected teacher route and not logged in, redirect to login
    if (isGoingToProtectedTeacherRoute &&
        !isGoingToLoginOrRegister &&
        !isLoggedIn) {
      return AppRoutes.login;
    }

    // If logged in and going to login/register, go to quiz creator
    if (isGoingToLoginOrRegister && isLoggedIn) {
      return AppRoutes.quizCreator;
    }

    // Otherwise, allow the route
    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.home,
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    // Teacher authentication routes
    GoRoute(
      path: AppRoutes.login,
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      },
    ),
    // Teacher routes
    GoRoute(
      path: AppRoutes.quizCreator,
      builder: (BuildContext context, GoRouterState state) {
        return const QuizCreatorScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.teacherLobby,
      builder: (BuildContext context, GoRouterState state) {
        return const TeacherLobbyScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.hostGame,
      builder: (BuildContext context, GoRouterState state) {
        return const HostGameScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.teacherLeaderboard,
      builder: (BuildContext context, GoRouterState state) {
        return const FinalLeaderboardScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.quizHistory,
      builder: (BuildContext context, GoRouterState state) {
        return const QuizHistoryScreen();
      },
    ),
    // Student routes
    GoRoute(
      path: AppRoutes.studentJoin,
      builder: (BuildContext context, GoRouterState state) {
        return const JoinScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.studentLobby,
      builder: (BuildContext context, GoRouterState state) {
        final args = state.extra as Map<String, String>?;
        return StudentLobbyScreen(
          pin: args?['pin'] ?? '',
          name: args?['name'] ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.studentQuestion,
      builder: (BuildContext context, GoRouterState state) {
        return const QuestionScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.studentLeaderboard,
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
