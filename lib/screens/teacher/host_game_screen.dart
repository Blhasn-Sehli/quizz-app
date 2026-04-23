import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import '../../providers/game_provider.dart';
import '../../widgets/timer_bar.dart';
import '../../widgets/fallback_state_screen.dart';
import '../../models/question.dart';
import '../../models/game_session.dart';

class HostGameScreen extends StatefulWidget {
  const HostGameScreen({Key? key}) : super(key: key);

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  bool _navigationTriggered = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final session = provider.session;
    final question = provider.currentQuestion;

    // ── GAME ENDED: navigate to leaderboard FIRST, before any null checks ──
    // When gameEnded=true, Firestore sets questionState='ended' and the
    // currentQuestionIndex may exceed the quiz length, making currentQuestion
    // return null. We must check gameEnded before the session/question guard.
    if (session != null &&
        provider.currentPin != null &&
        session.pin == provider.currentPin &&
        session.gameEnded &&
        !_navigationTriggered) {
      _navigationTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          GoRouter.of(context).go(AppRoutes.teacherLeaderboard);
        }
      });
      // Show a brief loading state while the callback fires
      return const FallbackStateScreen(
        icon: Icons.emoji_events_rounded,
        title: 'Game Over!',
        message: 'Loading final leaderboard...',
        isLoading: true,
      );
    }

    final isLaunching = provider.currentPin != null || provider.isGameStarted || provider.questionState != null;

    if (session == null || question == null) {
      if (isLaunching) {
        return const FallbackStateScreen(
          icon: Icons.sports_esports_rounded,
          title: 'Starting Game',
          message: 'Your session is being prepared. This usually takes a moment on web.',
          isLoading: true,
        );
      }

      return const FallbackStateScreen(
        icon: Icons.sports_esports_rounded,
        title: 'No Active Game',
        message: 'There is no running game right now. Go back to the quiz creator to start one.',
        primaryLabel: 'Back to Quiz Creator',
        primaryRoute: AppRoutes.quizCreator,
        secondaryLabel: 'Go Home',
        secondaryRoute: AppRoutes.home,
      );
    }

    final total = session.quiz.questions.length;
    final current = session.currentQuestionIndex + 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question counter
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Question $current of $total',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Timer info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withAlpha((0.5 * 255).round()), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Time: ${provider.timeRemaining}s / ${question.timeLimit}s',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Timer bar
              TimerBar(
                timeRemaining: provider.timeRemaining,
                totalTime: question.timeLimit,
                height: 16,
              ),
              const SizedBox(height: 20),
              // Question text
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.05 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withAlpha((0.1 * 255).round()),
                    width: 2,
                  ),
                ),
                child: Text(
                  question.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Student answers summary
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${session.students.where((s) => s.currentAnswer != null).length} / ${session.students.length} answered',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (session.gameStarted &&
                      provider.questionState == 'answering' &&
                      provider.timeRemaining > 0) ...[
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () => provider.endQuestion(),
                      icon: const Icon(Icons.timer_off, size: 18, color: Colors.white),
                      label: const Text('End Early', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Stats area
              Expanded(
                child: session.gameStarted &&
                        provider.questionState == 'answering' &&
                        provider.timeRemaining > 0
                    ? _buildLiveStats(question, session)
                    : _buildAnswerReview(context, question, session, provider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveStats(Question question, GameSession session) {
    Widget statsContent;
    switch (question.type) {
      case QuestionType.yesNo:
        statsContent = _buildBarStats(
          question,
          ['Yes', 'No'],
          [Colors.orange, Colors.blue],
          session,
        );
        break;
      case QuestionType.multipleChoice:
        final labels = question.options!
            .map((opt) => opt.length > 20 ? '${opt.substring(0, 18)}...' : opt)
            .toList();
        final colors = [
          const Color(0xFFE21B3C),
          const Color(0xFF1368CE),
          const Color(0xFFFFA602),
          const Color(0xFF26890C),
        ];
        statsContent = _buildBarStats(question, labels, colors, session, showLabels: true);
        break;
      case QuestionType.text:
        statsContent = _buildTextAnswersStats(question, session);
        break;
    }

    // For non-text questions, show student answer list above stats
    if (question.type != QuestionType.text) {
      return Column(
        children: [
          _buildStudentAnswerList(session),
          const SizedBox(height: 8),
          Expanded(child: statsContent),
        ],
      );
    } else {
      return statsContent;
    }
  }

  Widget _buildStudentAnswerList(GameSession session) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.05 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha((0.1 * 255).round())),
      ),
      child: ListView.builder(
        itemCount: session.students.length,
        itemBuilder: (context, index) {
          final student = session.students[index];
          final hasAnswered = student.currentAnswer != null;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 12,
              child: Text(
                student.name.isNotEmpty ? student.name[0] : '',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
            title: Text(
              student.name,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            trailing: Text(
              hasAnswered ? '✓ answered' : 'waiting...',
              style: TextStyle(
                fontSize: 12,
                color: hasAnswered ? Colors.greenAccent : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarStats(Question question, List<String> labels, List<Color> colors,
      GameSession session, {bool showLabels = false, int? highlightCorrect}) {
    final int optionCount = labels.length;
    final List<Widget> bars = [];

    for (int i = 0; i < optionCount; i++) {
      final count = session.answerCounts[i] ?? 0;
      final total = session.students.length;
      final percentage = total > 0 ? (count / total * 100).toDouble() : 0.0;
      final isCorrect = highlightCorrect != null && i == highlightCorrect;

      bars.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(6),
                      border: isCorrect
                          ? Border.all(color: Colors.green[400]!, width: 3)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        showLabels
                            ? String.fromCharCode(65 + i)
                            : (i == 0 ? '✓' : '✗'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toInt()}% (${count}/${total})',
                    style: TextStyle(
                      color: percentage > 0
                          ? (isCorrect ? Colors.green[400] : Colors.white)
                          : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (percentage > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween(begin: 0.0, end: percentage),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value / 100,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCorrect ? Colors.green : colors[i],
                        ),
                        minHeight: 8,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: bars,
    );
  }

  Widget _buildTextAnswersStats(Question question, GameSession session) {
    // Get students who submitted text answers
    final answeredStudents = session.students
        .where((s) => s.currentAnswer != null)
        .toList();

    if (answeredStudents.isEmpty) {
      return const Center(
        child: Text(
          'No answers yet...',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: answeredStudents.length,
      itemBuilder: (context, index) {
        final student = answeredStudents[index];
        final answer = student.currentAnswer.toString();
        final isCorrect = student.isCorrect ?? question.isAnswerCorrect(student.currentAnswer);
        final hasAnswerText = answer.trim().isNotEmpty;
        final statusColor = isCorrect ? Colors.green : Colors.red;
        final statusIcon = isCorrect ? Icons.check_circle : Icons.cancel;
        final avatarLabel = _initials(student.name);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCorrect
                ? Colors.green.withAlpha((0.2 * 255).round())
                : Colors.red.withAlpha((0.2 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor,
                child: Text(
                  avatarLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      hasAnswerText ? '"$answer"' : '"(empty)"',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                statusIcon,
                color: statusColor,
              ),
            ],
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';

    final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    final first = parts.first[0];
    final last = parts.last[0];
    return '$first$last'.toUpperCase();
  }

  Widget _buildAnswerReview(BuildContext context, Question question, GameSession session, GameProvider provider) {
    final correctIndex = provider.correctAnswer;
    final isGameEnded = provider.isGameEnded;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Correct answer banner
          if (question.type != QuestionType.text && correctIndex != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.green[700]?.withAlpha((0.8 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[400]!, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[400], size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'CORRECT ANSWER: ${String.fromCharCode(65 + correctIndex)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (question.type == QuestionType.text)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.green[700]?.withAlpha((0.8 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[400]!, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green[400], size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'KEYWORDS: ${question.correctAnswerText}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Live answer stats
          Text(
            'Answer Distribution',
            style: TextStyle(
              color: Colors.white.withAlpha((0.8 * 255).round()),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (question.type != QuestionType.text)
            _buildBarStats(question, question.options!, [
              const Color(0xFFE21B3C), // Red
              const Color(0xFF1368CE), // Blue
              const Color(0xFFFFA602), // Yellow
              const Color(0xFF26890C), // Green
            ], session, showLabels: true, highlightCorrect: correctIndex)
          else
            _buildTextAnswersStats(question, session),
          const SizedBox(height: 30),
          // Next button or end game
          if (!isGameEnded)
            ElevatedButton.icon(
              onPressed: () {
                provider.nextQuestion();
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next Question →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                GoRouter.of(context).go(AppRoutes.teacherLeaderboard);
              },
              icon: const Icon(Icons.leaderboard),
              label: const Text('View Final Leaderboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
