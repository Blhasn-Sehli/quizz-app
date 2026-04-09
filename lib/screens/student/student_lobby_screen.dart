import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:quizz_app/constants/app_colors.dart';
import '../../providers/game_provider.dart';

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

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Text(
            'Session not found. Invalid PIN?',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
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
        if (mounted) context.go('/student/leaderboard');
      });
    } else if (shouldShowQuestion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/student/question');
      });
    } else if (shouldRecoverToLeaderboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/student/leaderboard');
      });
    }

    final students = session.students;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
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
        ),
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // PIN pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.gradPin,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GAME PIN',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                    letterSpacing: 0.08,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.pin.split('').join(' '),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
              color: AppColors.success.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withAlpha(80)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.05,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO ─────────────────────────────────────────────
  Widget _buildHero() {
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
              gradient: AppColors.gradBtn,
              border: Border.all(color: AppColors.border, width: 3),
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
                color: AppColors.text,
              ),
              children: [
                const TextSpan(text: 'Welcome, '),
                TextSpan(
                  text: widget.name,
                  style: const TextStyle(color: AppColors.primaryLight),
                ),
                const TextSpan(text: '!'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "You're in the game lobby",
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── WAITING CARD ─────────────────────────────────────
  Widget _buildWaitingCard(bool gameStarted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gameStarted ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              gameStarted
                  ? 'Game is starting...'
                  : 'Waiting for teacher to start...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (!gameStarted)
              Text(
                'Stand by',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Text(
            'PLAYERS JOINED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.08,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '$count player${count == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryLight,
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
    if (students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Text(
              'Waiting for other students...',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
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
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Cycle avatar colors for other players
    final avatarColors = [
      [const Color(0xFFD85A30), const Color(0xFF993C1D)],
      [const Color(0xFF0F6E56), const Color(0xFF085041)],
      [const Color(0xFF185FA5), const Color(0xFF0C447C)],
      [const Color(0xFF993556), const Color(0xFF72243E)],
    ];
    final colorPair = avatarColors[index % avatarColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.surfaceHigh : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary : AppColors.border,
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
                  ? AppColors.gradBtnGreen
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
                color: AppColors.text,
              ),
            ),
          ),
          // Tag
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(38),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withAlpha(90),
                ),
              ),
              child: const Text(
                'You',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Text(
              'joined',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final delay = i * 0.33;
            final t = ((_controller.value - delay) % 1.0).abs();
            final opacity = 0.2 + (0.8 * (1 - (t * 2 - 1).abs()));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha((opacity * 255).round()),
              ),
            );
          },
        );
      }),
    );
  }
}