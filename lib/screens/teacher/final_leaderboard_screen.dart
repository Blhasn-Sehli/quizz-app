import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:quizz_app/constants/app_colors.dart';
import '../../providers/game_provider.dart';

class FinalLeaderboardScreen extends StatefulWidget {
  const FinalLeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<FinalLeaderboardScreen> createState() => _FinalLeaderboardScreenState();
}

class _FinalLeaderboardScreenState extends State<FinalLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final session = provider.session;

    if (session == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final sorted = session.sortedStudents;
    final top3 = sorted.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Confetti
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(_confettiController.value),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  // ✅ Responsive: max width for web, full width on mobile
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: [
                      _buildConfettiStrip(),
                      _buildHero(),
                      _buildStatsRow(sorted.length, sorted.isNotEmpty ? sorted.first.score : 0, session.quiz.questions.length),
                      const SizedBox(height: 28),
                      _buildPodium(top3),
                      _buildDivider(),
                      _buildRankingsList(sorted, provider.currentStudentName),
                      const SizedBox(height: 24),
                      _buildActions(context, provider),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONFETTI STRIP ────────────────────────────────────
  Widget _buildConfettiStrip() {
    final colors = [
      AppColors.primary, AppColors.warning, AppColors.success,
      AppColors.danger, AppColors.primaryLight, AppColors.warning,
      AppColors.accent, AppColors.success,
    ];
    return Row(
      children: colors
          .map((c) => Expanded(child: Container(height: 6, color: c)))
          .toList(),
    );
  }

  // ── HERO ─────────────────────────────────────────────
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.border, width: 3),
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Final Leaderboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Game over — here are the results',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── STATS ROW ─────────────────────────────────────────
  Widget _buildStatsRow(int players, int topScore, int questions) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          _statCard('$questions', 'Questions'),
          const SizedBox(width: 10),
          _statCard('$players', 'Players'),
          const SizedBox(width: 10),
          _statCard('$topScore', 'Top score'),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  // ── PODIUM ────────────────────────────────────────────
  Widget _buildPodium(List<dynamic> top3) {
    if (top3.isEmpty) return const SizedBox();

    final podiumOrder = <int>[]; // index into top3: [1,0,2]
    if (top3.length == 1) {
      podiumOrder.addAll([0]);
    } else if (top3.length == 2) {
      podiumOrder.addAll([1, 0]);
    } else {
      podiumOrder.addAll([1, 0, 2]);
    }

    final heights = [60.0, 90.0, 46.0]; // block heights for 2nd, 1st, 3rd
    final avatarSizes = [54.0, 68.0, 50.0];
    final medals = ['🥈', '🥇', '🥉'];
    final rankNums = [2, 1, 3];
    final blockColors = [
      AppColors.textMuted.withAlpha(40),
      AppColors.primary.withAlpha(30),
      AppColors.danger.withAlpha(25),
    ];
    final blockBorders = [
      AppColors.textMuted.withAlpha(60),
      AppColors.primary.withAlpha(60),
      AppColors.danger.withAlpha(50),
    ];
    final avatarGrads = [
      [const Color(0xFF64748B), const Color(0xFF475569)],
      [AppColors.primary, AppColors.accent],
      [const Color(0xFFD85A30), const Color(0xFF993C1D)],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: podiumOrder.asMap().entries.map((entry) {
          final visualPos = entry.key; // 0=left(2nd), 1=center(1st), 2=right(3rd)
          final dataIndex = entry.value; // index in top3
          if (dataIndex >= top3.length) return const SizedBox(width: 8);
          final player = top3[dataIndex];
          final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(medals[visualPos],
                    style: TextStyle(
                        fontSize: visualPos == 1 ? 26 : 20)),
                const SizedBox(height: 6),
                // Avatar
                Container(
                  width: avatarSizes[visualPos],
                  height: avatarSizes[visualPos],
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: avatarGrads[visualPos],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: visualPos == 1 ? AppColors.primaryLight : AppColors.border,
                      width: visualPos == 1 ? 3 : 2,
                    ),
                  ),
                  child: Center(
                    child: Text(initial,
                        style: TextStyle(
                          fontSize: avatarSizes[visualPos] * 0.35,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  player.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${player.score} pts',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                  ),
                ),
                const SizedBox(height: 8),
                // Block
                Container(
                  height: heights[visualPos],
                  decoration: BoxDecoration(
                    color: blockColors[visualPos],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    border: Border.all(color: blockBorders[visualPos]),
                  ),
                  child: Center(
                    child: Text(
                      '${rankNums[visualPos]}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: visualPos == 1
                            ? AppColors.primaryLight
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── DIVIDER ───────────────────────────────────────────
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.border)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'FULL RANKINGS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.1),
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.border)),
        ],
      ),
    );
  }

  // ── RANKINGS LIST ─────────────────────────────────────
  Widget _buildRankingsList(List<dynamic> sorted, String? currentName) {
    final avatarGradients = [
      [AppColors.primary, AppColors.accent],
      [const Color(0xFFD85A30), const Color(0xFF993C1D)],
      [const Color(0xFF0F6E56), const Color(0xFF085041)],
      [const Color(0xFF185FA5), const Color(0xFF0C447C)],
      [const Color(0xFF993556), const Color(0xFF72243E)],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final index = entry.key;
          final student = entry.value;
          final rank = index + 1;
          final isMe = currentName != null &&
              student.name.toLowerCase() == currentName.toLowerCase();
          final initial =
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?';
          final av = avatarGradients[index % avatarGradients.length];

          Color rankBg;
          Color rankText = Colors.white;
          if (rank == 1) rankBg = const Color(0xFFF59E0B);
          else if (rank == 2) rankBg = const Color(0xFF94A3B8);
          else if (rank == 3) rankBg = const Color(0xFFD85A30);
          else { rankBg = AppColors.surfaceHigh; rankText = AppColors.textSub; }

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
                // Rank badge
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: rankBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: rank <= 3
                        ? Text(['🥇','🥈','🥉'][rank-1],
                            style: const TextStyle(fontSize: 14))
                        : Text('$rank',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: rankText)),
                  ),
                ),
                const SizedBox(width: 10),
                // Avatar
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isMe
                          ? [const Color(0xFF059669), const Color(0xFF10B981)]
                          : av,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(student.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text)),
                ),
                if (isMe) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(38),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withAlpha(80)),
                    ),
                    child: const Text('You',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('${student.score}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── ACTION BUTTONS ────────────────────────────────────
  Widget _buildActions(BuildContext context, GameProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _actionBtn(
              label: 'Back to Home',
              icon: Icons.home_rounded,
              isGradient: false,
              onTap: () {
                provider.resetGame();
                context.go('/');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionBtn(
              label: 'Play Again',
              icon: Icons.replay_rounded,
              isGradient: true,
              onTap: () {
                provider.resetGame();
                context.push('/teacher/quiz-creator');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required bool isGradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isGradient ? AppColors.gradBtnGreen : null,
          color: isGradient ? null : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isGradient ? Colors.transparent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isGradient ? Colors.white : AppColors.text, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isGradient ? Colors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CONFETTI ──────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter(this.progress);

  static const _colors = [
    Color(0xFF6366F1), Color(0xFFF59E0B), Color(0xFF10B981),
    Color(0xFFEF4444), Color(0xFF818CF8), Color(0xFF7C3AED),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < 60; i++) {
      final x = size.width * ((i * 0.137 + progress * 0.7) % 1.0);
      final y = size.height *
          ((i * 0.19 + progress * (0.8 + (i % 3) * 0.15)) % 1.0);
      final color = _colors[i % _colors.length];
      final radius = 2.0 + (i % 4).toDouble();
      paint.color = color.withAlpha(160);

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      } else if (i % 3 == 1) {
        canvas.drawRect(
            Rect.fromCenter(center: Offset(x, y), width: radius * 2, height: radius * 2),
            paint);
      } else {
        final path = Path()
          ..moveTo(x, y - radius)
          ..lineTo(x + radius, y + radius)
          ..lineTo(x - radius, y + radius)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}