import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import '../../constants/app_theme.dart';
import '../../providers/game_provider.dart';
import '../../widgets/fallback_state_screen.dart';
import '../../widgets/theme_toggle.dart';

class StudentLobbyScreen extends StatefulWidget {
  final String pin;
  final String name;

  const StudentLobbyScreen({
    Key? key,
    required this.pin,
    required this.name,
  }) : super(key: key);

  @override
  State<StudentLobbyScreen> createState() => _StudentLobbyScreenState();
}

class _StudentLobbyScreenState extends State<StudentLobbyScreen> {

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final session = provider.session;
    final currentQuestion = provider.currentQuestion;

    final isJoining = provider.currentPin != null || provider.currentStudentName != null;

    if (session == null) {
      if (isJoining) {
        return const FallbackStateScreen(
          icon: Icons.sync_rounded,
          title: 'Joining Session',
          message: 'Please wait while we load your game.',
          isLoading: true,
        );
      }

      return const FallbackStateScreen(
        icon: Icons.vpn_key_rounded,
        title: 'Session Not Found',
        message: 'That PIN no longer has an active session. Join again with a valid code.',
        primaryLabel: 'Join Again',
        primaryRoute: AppRoutes.studentJoin,
        secondaryLabel: 'Go Home',
        secondaryRoute: AppRoutes.home,
      );
    }

    final questionState = session.questionState;
    final shouldShowLeaderboard =
        session.gameEnded ||
        questionState == 'ended' ||
        questionState == 'revealed' ||
        questionState == 'between';
    final shouldShowQuestion =
        session.gameStarted &&
        !shouldShowLeaderboard &&
      currentQuestion != null &&
        (questionState == null || questionState == 'answering');

    final shouldRecoverToLeaderboard =
      session.gameStarted && !shouldShowLeaderboard && currentQuestion == null;

    if (shouldShowLeaderboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.studentLeaderboard);
      });
    } else if (shouldShowQuestion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.studentQuestion);
      });
    } else if (shouldRecoverToLeaderboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.studentLeaderboard);
      });
    }

    final students = session.students;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final t = context.tokens;
            return Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHero(),
                    _buildWaitingCard(session.gameStarted),
                    const SizedBox(height: 8),
                    _buildSectionHeader(students.length),
                    const SizedBox(height: 8),
                    _buildPlayersList(students),
                    const SizedBox(height: 12),
                    const _AnimatedDots(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
          },
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────
  Widget _buildTopBar() {
    return Builder(
      builder: (context) {
        final t = context.tokens;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border(bottom: BorderSide(color: t.border)),
          ),
          child: Row(
            children: [
              // PIN pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [t.primaryDim, t.primary, t.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GAME PIN',
                      style: TextStyle(
                        fontSize: 10,
                        color: t.text.withOpacity(0.6),
                        letterSpacing: 0.08,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.pin.split('').join(' '),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: t.text,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Live badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: t.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.success.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t.success,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 11,
                        color: t.success,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ThemeToggle(),
            ],
          ),
        );
      },
    );
  }

  // ── HERO ─────────────────────────────────────────────
  Widget _buildHero() {
    final t = context.tokens;
    final initial = widget.name.isNotEmpty
        ? widget.name[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [t.primaryDim, t.primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border.all(color: t.border, width: 3),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              children: [
                const TextSpan(text: 'Welcome, '),
                TextSpan(
                  text: widget.name,
                  style: TextStyle(color: t.primaryGlow),
                ),
                const TextSpan(text: '!'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "You're in the game lobby",
            style: TextStyle(fontSize: 13, color: t.textMuted),
          ),
        ],
      ),
    );
  }

  // ── WAITING CARD ─────────────────────────────────────
  Widget _buildWaitingCard(bool gameStarted) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gameStarted ? t.success : t.warning,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              gameStarted
                  ? 'Game is starting...'
                  : 'Waiting for teacher to start...',
              style: TextStyle(
                fontSize: 13,
                color: t.textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (!gameStarted)
              Text(
                'Stand by',
                style: TextStyle(
                  fontSize: 12,
                  color: t.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── SECTION HEADER ───────────────────────────────────
  Widget _buildSectionHeader(int count) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'PLAYERS JOINED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: t.textMuted,
              letterSpacing: 0.08,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: t.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: t.border),
            ),
            child: Text(
              '$count player${count == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                color: t.primaryGlow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PLAYERS LIST ─────────────────────────────────────
  Widget _buildPlayersList(List<dynamic> students) {
    final t = context.tokens;
    if (students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border),
          ),
          child: Center(
            child: Text(
              'Waiting for other students...',
              style: TextStyle(color: t.textMuted, fontSize: 14),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: students.asMap().entries.map((entry) {
          final student = entry.value;
          final isMe = student.name.toLowerCase() ==
              widget.name.toLowerCase();
          return _buildPlayerRow(student.name, isMe, entry.key);
        }).toList(),
      ),
    );
  }

  Widget _buildPlayerRow(String name, bool isMe, int index) {
    final t = context.tokens;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Cycle avatar colors for other players
    final avatarColors = [
      [t.accentDim, t.accent],
      [t.primaryDim, t.primary],
      [t.warning, t.accentDim],
      [t.primaryGlow, t.primary],
    ];
    final colorPair = avatarColors[index % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? t.surfaceHigh : t.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? t.primary : t.border,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isMe
                  ? LinearGradient(
                    colors: [t.success.withOpacity(0.85), t.success],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                  : LinearGradient(
                      colors: colorPair,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          // Tag
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: t.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: t.primary.withOpacity(0.35),
                ),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 11,
                  color: t.primaryGlow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Text(
              'joined',
              style: TextStyle(fontSize: 11, color: t.textMuted),
            ),
        ],
      ),
    );
  }
}

// ── ANIMATED DOTS ────────────────────────────────────────
class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final delay = i * 0.33;
            final phase = ((_controller.value - delay) % 1.0).abs();
            final opacity = 0.2 + (0.8 * (1 - (phase * 2 - 1).abs()));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.primary.withOpacity(opacity),
              ),
            );
          },
        );
      }),
    );
  }
}