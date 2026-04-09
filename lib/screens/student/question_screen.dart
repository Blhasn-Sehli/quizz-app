import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../widgets/answer_button.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({Key? key}) : super(key: key);

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int? _selectedAnswer;
  bool _answerLocked = false;
  String? _resultMessage; // 'correct', 'wrong', 'timeout'
  int? _pointsEarned;
  int? _lastQuestionIndex;
  String? _lastQuestionState;
  Timer? _navigationTimer;
  bool _fallbackNavigationQueued = false;

  // ✅ Track reveal handling to prevent duplicate setState in build()
  bool _revealHandled = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<GameProvider>(context, listen: false);
    _lastQuestionIndex = provider.currentQuestionIndex;
    _lastQuestionState = provider.questionState;
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  // ✅ This now correctly resets state for every new question
  void _checkAndResetIfNeeded(GameProvider provider) {
    final currentIndex = provider.currentQuestionIndex;
    final currentState = provider.questionState;

    final questionChanged = currentIndex != _lastQuestionIndex;
    final stateResetToAnswering =
        currentState == 'answering' && _lastQuestionState == 'revealed';

    if (questionChanged || stateResetToAnswering) {
      _navigationTimer?.cancel();
      _navigationTimer = null;

      // ✅ Use addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedAnswer = null;
            _answerLocked = false;
            _resultMessage = null;
            _pointsEarned = null;
            _revealHandled = false; // ✅ Reset reveal guard
          });
        }
      });

      _lastQuestionIndex = currentIndex;
      _lastQuestionState = currentState;
    }
  }

  // ✅ Handle reveal OUTSIDE build() using postFrameCallback
  void _handleReveal(GameProvider provider, int? correctIndex, int timeRemaining, int basePoints) {
    if (_revealHandled) return; // ✅ Prevent duplicate handling
    _revealHandled = true;

    String result;
    int points;

    if (_selectedAnswer == null) {
      result = 'timeout';
      points = 0;
    } else {
      final isCorrect = _selectedAnswer == correctIndex;
      final timeBonus = timeRemaining * 10;
      points = isCorrect ? (basePoints + timeBonus) : 0;
      result = isCorrect ? 'correct' : 'wrong';
    }

    // ✅ Safe setState via postFrameCallback (not inside build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _resultMessage = result;
          _pointsEarned = points;
        });

        // ✅ Navigate after 3 seconds
        _navigationTimer?.cancel();
        _navigationTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            GoRouter.of(context).go('/student/leaderboard');
          }
        });
      }
    });
  }

  void _handleAnswer(int answerIndex) {
    if (_answerLocked) return;
    setState(() {
      _answerLocked = true;
      _selectedAnswer = answerIndex;
    });
    final provider = Provider.of<GameProvider>(context, listen: false);
    provider.submitStudentAnswer(answerIndex);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final question = provider.currentQuestion;
    final session = provider.session;

    if (session == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(
          child: Text('No active question',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    if (question == null) {
      if (!_fallbackNavigationQueued) {
        _fallbackNavigationQueued = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final state = provider.questionState;
          if (provider.isGameEnded || state == 'ended' || state == 'revealed') {
            context.go('/student/leaderboard');
          } else {
            context.go('/student/lobby');
          }
        });
      }

      return const Scaffold(
        backgroundColor: Color(0xFF0D1B2A),
        body: Center(
          child: Text(
            'Syncing game state...',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final options = question.options ?? const <String>[];

    final total = session.quiz.questions.length;
    final current = provider.currentQuestionIndex + 1;
    final timeRemaining = provider.timeRemaining;
    final questionState = provider.questionState;
    final correctIndex = provider.correctAnswer;

    final isRevealed = questionState == 'revealed';
    final isAnswering = !isRevealed &&
        provider.isGameStarted &&
        timeRemaining > 0 &&
        (questionState == 'answering' || questionState == null);

    // ✅ Check for question reset FIRST (before reveal handling)
    _checkAndResetIfNeeded(provider);

    // ✅ Handle reveal safely (guarded by _revealHandled flag)
    if (isRevealed && !_revealHandled) {
      _handleReveal(provider, correctIndex, timeRemaining, question.points);
    }

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

              // Timer bar
              _buildTimerBar(timeRemaining, question.timeLimit),
              const SizedBox(height: 30),

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
              const SizedBox(height: 30),

              // Answer buttons
              Expanded(
                child: options.isEmpty
                    ? const Center(
                        child: Text(
                          'Waiting for question options...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(options.length, (index) {
                          final isSelected = _selectedAnswer == index;
                          final isCorrectAnswer = correctIndex == index;

                          return AnswerButton(
                            text: options[index],
                            index: index,
                            isSelected: isSelected,
                            isCorrect: isCorrectAnswer,
                            showResult: isRevealed,
                            isEnabled: !_answerLocked && isAnswering,
                            onPressed: () => _handleAnswer(index),
                          );
                        }),
                      ),
              ),

              // Result message
              if (_resultMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _resultMessage == 'correct'
                        ? Colors.green[700]?.withAlpha((0.8 * 255).round())
                        : _resultMessage == 'wrong'
                            ? Colors.red[700]?.withAlpha((0.8 * 255).round())
                            : Colors.grey[700]?.withAlpha((0.8 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _resultMessage == 'correct'
                            ? Icons.check_circle
                            : _resultMessage == 'wrong'
                                ? Icons.cancel
                                : Icons.access_time,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _resultMessage == 'correct'
                            ? 'Correct! +$_pointsEarned pts'
                            : _resultMessage == 'wrong'
                                ? 'Wrong! 0 pts'
                                : 'Too slow!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Waiting spinner (answer locked but not revealed yet)
              if (_answerLocked && !isRevealed && _resultMessage == null) ...[
                const SizedBox(height: 10),
                const Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Answer locked! Waiting for reveal...',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerBar(int timeRemaining, int totalTime) {
    // ✅ Guard against division by zero
    final progress = totalTime > 0 ? (timeRemaining / totalTime).clamp(0.0, 1.0) : 0.0;

    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: progress > 0.5
                  ? [Colors.green[400]!, Colors.green[600]!]
                  : progress > 0.25
                      ? [Colors.orange[400]!, Colors.orange[600]!]
                      : [Colors.red[400]!, Colors.red[600]!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: progress > 0.5
                    ? Colors.green.withAlpha((0.5 * 255).round())
                    : progress > 0.25
                        ? Colors.orange.withAlpha((0.5 * 255).round())
                        : Colors.red.withAlpha((0.5 * 255).round()),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}