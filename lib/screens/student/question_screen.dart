import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/game_provider.dart';
import '../../widgets/answer_button.dart';
import '../../widgets/fallback_state_screen.dart';
import '../../widgets/theme_toggle.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({Key? key}) : super(key: key);

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final TextEditingController _textAnswerController = TextEditingController();

  dynamic _selectedAnswer;
  bool _answerLocked = false;
  String? _resultMessage;
  int? _pointsEarned;
  Timer? _navigationTimer;

  // Track the last question index and state we have already processed,
  // so _syncWithProvider only reacts to ACTUAL changes, not every rebuild.
  int? _shownQuestionIndex;
  String? _shownQuestionState;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<GameProvider>(context, listen: false);
    _shownQuestionIndex = provider.currentQuestionIndex;
    _shownQuestionState = provider.questionState;
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _textAnswerController.dispose();
    super.dispose();
  }

  // Pure read — compares current provider values against what we last
  // processed and schedules side-effects via addPostFrameCallback.
  // Never calls setState directly.
  void _syncWithProvider(GameProvider provider) {
    final newIndex = provider.currentQuestionIndex;
    final newState = provider.questionState;

    final indexChanged = newIndex != _shownQuestionIndex;
    final backToAnswering =
        newState == 'answering' && _shownQuestionState == 'revealed';
    final justRevealed =
        newState == 'revealed' && _shownQuestionState != 'revealed';

    if (indexChanged || backToAnswering) {
      // A new question started — update tracking first so we don't
      // trigger this branch again on the very next rebuild.
      _shownQuestionIndex = newIndex;
      _shownQuestionState = newState;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onNewQuestion());
      return;
    }

    if (justRevealed) {
      _shownQuestionState = newState;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onReveal(provider));
      return;
    }

    // Timer tick or other innocuous update — just keep tracking in sync.
    _shownQuestionIndex = newIndex;
    _shownQuestionState = newState;
  }

  void _onNewQuestion() {
    if (!mounted) return;
    _navigationTimer?.cancel();
    _navigationTimer = null;
    setState(() {
      _selectedAnswer = null;
      _answerLocked = false;
      _resultMessage = null;
      _pointsEarned = null;
      _textAnswerController.clear();
    });
  }

  void _onReveal(GameProvider provider) {
    if (!mounted) return;
    if (_resultMessage != null) return; // already showing result

    final question = provider.currentQuestion;

    // For text questions pick up whatever the student typed even if they
    // didn't press Submit before time ran out.
    dynamic effectiveAnswer = _selectedAnswer;
    if (effectiveAnswer == null && question?.type.name == 'text') {
      final typed = _textAnswerController.text.trim();
      if (typed.isNotEmpty) effectiveAnswer = typed;
    }

    String result;
    int points;

    if (effectiveAnswer == null ||
        (effectiveAnswer is String && effectiveAnswer.isEmpty)) {
      result = 'timeout';
      points = 0;
    } else {
      final isCorrect = question?.isAnswerCorrect(effectiveAnswer) ?? false;
      points = isCorrect ? question!.points : 0;
      result = isCorrect ? 'correct' : 'wrong';
    }

    setState(() {
      _resultMessage = result;
      _pointsEarned = points;
      _answerLocked = true;
    });

    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      GoRouter.of(context).go(AppRoutes.studentLeaderboard);
    });
  }

  void _handleAnswer(dynamic answer) {
    if (_answerLocked || !mounted) return;
    setState(() {
      _answerLocked = true;
      _selectedAnswer = answer;
    });
    Provider.of<GameProvider>(
      context,
      listen: false,
    ).submitStudentAnswer(answer);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final question = provider.currentQuestion;
    final session = provider.session;

    // Sync — read only, side-effects deferred to postFrameCallback
    _syncWithProvider(provider);

    if (session == null) {
      return const FallbackStateScreen(
        icon: Icons.sync_rounded,
        title: 'Loading Question',
        message: 'Syncing your game. Please wait.',
        isLoading: true,
      );
    }

    if (provider.isGameEnded && _resultMessage == null) {
      return const FallbackStateScreen(
        icon: Icons.emoji_events_rounded,
        title: 'Game Finished',
        message: 'Taking you to the final leaderboard.',
        isLoading: true,
      );
    }

    if (question == null) {
      return const FallbackStateScreen(
        icon: Icons.sync_rounded,
        title: 'Loading Question',
        message: 'The next question is on its way.',
        isLoading: true,
      );
    }

    final options = question.options ?? const <String>[];
    final total = session.quiz.questions.length;
    final current = provider.currentQuestionIndex + 1;
    final timeRemaining = provider.timeRemaining;
    final questionState = provider.questionState;
    final correctIndex = provider.correctAnswer;

    final isRevealed = questionState == 'revealed' || _resultMessage != null;
    final isAnswering =
        !isRevealed &&
        !_answerLocked &&
        provider.isGameStarted &&
        timeRemaining > 0 &&
        (questionState == 'answering' || questionState == null);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Builder(
            builder: (context) {
              final t = context.tokens;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar with question counter and theme toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Question counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: t.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Question $current of $total',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const ThemeToggle(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Timer bar
                  _buildTimerBar(timeRemaining, question.timeLimit),
                  const SizedBox(height: 30),

                  // Question text
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.border, width: 2),
                    ),
                    child: Text(
                      question.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t.text,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Answer area
                  Expanded(
                    child: question.type.name == 'text'
                        ? _buildTextInput(isAnswering, isRevealed, question)
                        : options.isEmpty
                        ? Center(
                            child: Text(
                              'Waiting for options...',
                              style: TextStyle(
                                color: t.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(options.length, (i) {
                              return AnswerButton(
                                text: options[i],
                                index: i,
                                isSelected: _selectedAnswer == i,
                                isCorrect: correctIndex == i,
                                showResult: isRevealed,
                                isEnabled: !_answerLocked && isAnswering,
                                onPressed: () => _handleAnswer(i),
                              );
                            }),
                          ),
                  ),

                  // Result banner
                  if (_resultMessage != null) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final t = context.tokens;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _resultMessage == 'correct'
                                ? t.success
                                : _resultMessage == 'wrong'
                                ? t.danger
                                : t.textMuted,
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
                                color: t.text,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _resultMessage == 'correct'
                                    ? 'Correct! +$_pointsEarned pts'
                                    : _resultMessage == 'wrong'
                                    ? 'Wrong answer'
                                    : "Time's up!",
                                style: TextStyle(
                                  color: t.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // Waiting spinner
                  if (_answerLocked && _resultMessage == null) ...[
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final t = context.tokens;
                        return Center(
                          child: Column(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    t.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Answer locked! Waiting for results...',
                                style: TextStyle(
                                  color: t.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput(bool isAnswering, bool isRevealed, dynamic question) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Builder(
          builder: (context) {
            final t = context.tokens;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_answerLocked && _selectedAnswer != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Your answer: "$_selectedAnswer"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t.textSub,
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  TextField(
                    controller: _textAnswerController,
                    enabled: !_answerLocked && !isRevealed,
                    autofocus: true,
                    style: TextStyle(color: t.text, fontSize: 18),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: isRevealed
                          ? 'Time is up'
                          : 'Type your answer...',
                      hintStyle: TextStyle(color: t.textMuted),
                      filled: true,
                      fillColor: t.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: t.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (val) {
                      final trimmed = val.trim();
                      if (trimmed.isNotEmpty && !_answerLocked && !isRevealed) {
                        _handleAnswer(trimmed);
                      }
                    },
                  ),
                const SizedBox(height: 16),
                if (!_answerLocked && !isRevealed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = _textAnswerController.text.trim();
                        if (val.isNotEmpty) _handleAnswer(val);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: t.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Submit Answer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: t.text,
                        ),
                      ),
                    ),
                  ),
                if (isRevealed && question?.correctAnswerText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: t.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: t.success.withOpacity(0.5)),
                    ),
                    child: Text(
                      'Keywords: ${question!.correctAnswerText}',
                      style: TextStyle(color: t.success, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimerBar(int timeRemaining, int totalTime) {
    final t = context.tokens;
    final progress = totalTime > 0
        ? (timeRemaining / totalTime).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: progress > 0.5
                  ? [t.success.withOpacity(0.8), t.success]
                  : progress > 0.25
                  ? [t.warning.withOpacity(0.8), t.warning]
                  : [t.danger.withOpacity(0.8), t.danger],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
