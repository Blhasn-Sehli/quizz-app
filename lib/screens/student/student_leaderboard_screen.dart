import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import '../../constants/app_theme.dart';
import '../../providers/game_provider.dart';
import '../../widgets/fallback_state_screen.dart';
import '../../widgets/theme_toggle.dart';

class StudentLeaderboardScreen extends StatefulWidget {
  const StudentLeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentLeaderboardScreen> createState() =>
      _StudentLeaderboardScreenState();
}

class _StudentLeaderboardScreenState
    extends State<StudentLeaderboardScreen> {
  int? _arrivedAtIndex;
  String? _arrivedAtState;
  bool _navigationTriggered = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<GameProvider>(context, listen: false);
    _arrivedAtIndex = provider.currentQuestionIndex;
    _arrivedAtState = provider.questionState;
  }

  void _tryNavigate(GameProvider provider) {
    if (_navigationTriggered) return;
    if (provider.session == null) return;
    if (provider.isGameEnded) return;

    final currentIndex = provider.currentQuestionIndex;
    final currentState = provider.questionState;

    bool shouldGoToQuestion = false;

    if (currentIndex != _arrivedAtIndex) {
      shouldGoToQuestion = true;
    } else if (currentState == 'answering' && _arrivedAtState == 'revealed') {
      shouldGoToQuestion = true;
    }

    if (shouldGoToQuestion) {
      _navigationTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(AppRoutes.studentQuestion);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final t = context.tokens;
    final session = provider.session;
    final isEnded = provider.isGameEnded;
    final isJoiningOrSyncing = provider.currentPin != null || provider.currentStudentName != null;

    _tryNavigate(provider);

    if (session == null) {
      if (isJoiningOrSyncing) {
        return const FallbackStateScreen(
          icon: Icons.sync_rounded,
          title: 'Loading Leaderboard',
          message: 'We are syncing the latest game results.',
          isLoading: true,
        );
      }

      return const FallbackStateScreen(
        icon: Icons.leaderboard_rounded,
        title: 'Leaderboard Unavailable',
        message: 'The game session is no longer available. Join again to continue.',
        primaryLabel: 'Join Again',
        primaryRoute: AppRoutes.studentJoin,
        secondaryLabel: 'Go Home',
        secondaryRoute: AppRoutes.home,
      );
    }

    final players = session.sortedStudents;
    final currentStudentName = provider.currentStudentName;
    final isMe = (String name) =>
        currentStudentName != null &&
        name.toLowerCase() == currentStudentName.toLowerCase();

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(players.length),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final student = players[index];
                  return _buildPlayerRow(
                      student, index + 1, isMe(student.name));
                },
              ),
            ),
            _buildStatusBox(provider.timeRemaining, isEnded),
            if (isEnded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildReplayButton(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const ThemeToggle(),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [t.primaryDim, t.primary],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.leaderboard_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Leaderboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: t.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Top $count players',
            style: TextStyle(fontSize: 13, color: t.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(dynamic student, int rank, bool isCurrentPlayer) {
    final t = context.tokens;
    final initial =
        student.name.isNotEmpty ? student.name[0].toUpperCase() : '?';

    final rankColors = {
      1: [t.warning, t.accentDim],
      2: [t.textMuted, t.textSub],
      3: [t.primary, t.primaryDim],
    };
    final rankColor = rankColors[rank];
    final avatarColors = [
      [t.accent, t.accentDim],
      [t.primary, t.primaryDim],
      [t.success, t.accentDim],
      [t.primaryGlow, t.primary],
    ];
    final av = avatarColors[(rank - 1) % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? t.surfaceHigh : t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentPlayer ? t.primary : t.border,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              gradient: rankColor != null
                  ? LinearGradient(
                      colors: rankColor,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: rankColor == null ? t.surfaceHigh : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank',
                style: TextStyle(
                  fontSize: rank <= 3 ? 14 : 11,
                  fontWeight: FontWeight.bold,
                  color: rank > 3 ? t.textSub : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isCurrentPlayer
                    ? [t.success.withOpacity(0.85), t.success]
                    : av,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name
          Expanded(
            child: Text(
              student.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
          ),
          if (isCurrentPlayer) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: t.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.primary.withOpacity(0.3)),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 10,
                  color: t.primaryGlow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.border),
            ),
            child: Text(
              '${student.score}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: t.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(int timeRemaining, bool isEnded) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.primary.withOpacity(0.24)),
      ),
      child: Column(
        children: [
          Text(
            isEnded ? 'Game finished' : 'Next question starting in',
            style: TextStyle(fontSize: 13, color: t.textSub),
          ),
          const SizedBox(height: 6),
          if (isEnded) ...[
            Text(
              'Final leaderboard',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: t.primaryGlow,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'You can review the final standings here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: t.textMuted),
            ),
          ] else ...[
            Text(
              '${timeRemaining}s',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: t.primaryGlow,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Get ready!',
              style: TextStyle(fontSize: 11, color: t.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplayButton() {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.primaryDim, t.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: t.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            _navigationTriggered = true;
            final provider = Provider.of<GameProvider>(context, listen: false);
            provider.resetGame();
            if (mounted) {
              context.go(AppRoutes.studentJoin);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.replay_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Replay Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}