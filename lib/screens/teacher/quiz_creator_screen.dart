import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../models/question.dart';
import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';

// ─── Quiz Creator Screen ──────────────────────────────────────────────────────
class QuizCreatorScreen extends StatefulWidget {
  const QuizCreatorScreen({Key? key}) : super(key: key);

  @override
  State<QuizCreatorScreen> createState() => _QuizCreatorScreenState();
}

class _QuizCreatorScreenState extends State<QuizCreatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  List<Question> _questions = [];
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fabAnim.dispose();
    super.dispose();
  }

  // ── helpers ──
  Color _typeColor(QuestionType t) => switch (t) {
        QuestionType.yesNo         => const Color(0xFFF59E0B),
        QuestionType.multipleChoice => AppColors.primary,
        QuestionType.text          => AppColors.accentLight,
      };

  String _typeLabel(QuestionType t) => switch (t) {
        QuestionType.yesNo          => 'Yes / No',
        QuestionType.multipleChoice => 'Multiple Choice',
        QuestionType.text           => 'Text Answer',
      };

  IconData _typeIcon(QuestionType t) => switch (t) {
        QuestionType.yesNo          => Icons.thumbs_up_down_rounded,
        QuestionType.multipleChoice => Icons.checklist_rounded,
        QuestionType.text           => Icons.edit_note_rounded,
      };

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(color: Colors.white)),
          ]),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(color: Colors.white)),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

  Future<void> _addQuestion() async {
    final result = await showDialog<Question>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => const QuestionEditDialog(),
    );
    if (result != null) setState(() => _questions.add(result));
  }

  Future<void> _editQuestion(int index) async {
    final result = await showDialog<Question>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => QuestionEditDialog(question: _questions[index]),
    );
    if (result != null) setState(() => _questions[index] = result);
  }

  void _deleteQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  // ── build ──
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(context, provider),
      body: isWide
          ? _buildWideLayout(context, provider)
          : _buildNarrowLayout(context, provider),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, GameProvider provider) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: AppColors.gradBtn,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
      ),
      title: const Text(
        'Quiz Creator',
        style: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
      actions: [
        // Save
        _AppBarBtn(
          icon: Icons.save_rounded,
          label: 'Save',
          gradient: AppColors.gradBtn,
          onTap: () async {
            if (_titleController.text.trim().isEmpty) {
              _showError('Please enter a quiz title');
              return;
            }
            if (_questions.isEmpty) {
              _showError('Add at least one question');
              return;
            }
            provider.saveQuiz(_titleController.text.trim(), _questions);
            if (mounted) _showSuccess('Quiz saved!');
          },
        ),
        const SizedBox(width: 8),
        // Load
        PopupMenuButton<int>(
          tooltip: 'Load Quiz',
          color: AppColors.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.folder_open_rounded, color: AppColors.primaryLight, size: 18),
                SizedBox(width: 6),
                Text('Load', style: TextStyle(color: AppColors.primaryLight, fontSize: 13)),
              ],
            ),
          ),
          onSelected: (int index) {
            final quiz = provider.savedQuizzes[index];
            setState(() {
              _titleController.text = quiz.title;
              _questions = List.from(quiz.questions);
            });
          },
          itemBuilder: (context) {
            final quizzes = provider.savedQuizzes;
            if (quizzes.isEmpty) {
              return [
                const PopupMenuItem<int>(
                  enabled: false,
                  child: Text('No saved quizzes',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ];
            }
            return quizzes
                .asMap()
                .entries
                .map((e) => PopupMenuItem<int>(
                      value: e.key,
                      child: Text(e.value.title,
                          style: const TextStyle(color: AppColors.text)),
                    ))
                .toList();
          },
        ),
        const SizedBox(width: 8),
        // History
        IconButton(
          icon: const Icon(Icons.history_rounded, color: AppColors.textSub),
          tooltip: 'Quiz History',
          onPressed: () => context.push('/teacher/quiz-history'),
        ),
        // Logout
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: AppColors.textSub),
          tooltip: 'Logout',
          onPressed: () async {
            try {
              await AuthService().signOut();
              if (mounted) context.go('/');
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout error: $e')));
              }
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Wide layout (two-column) ──
  Widget _buildWideLayout(BuildContext context, GameProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel – config
        SizedBox(
          width: 340,
          child: Container(
            color: AppColors.surface,
            child: _buildLeftPanel(context, provider),
          ),
        ),
        Container(width: 1, color: AppColors.border),
        // Right panel – questions
        Expanded(child: _buildQuestionsPanel(context, provider)),
      ],
    );
  }

  // ── Narrow layout (stacked) ──
  Widget _buildNarrowLayout(BuildContext context, GameProvider provider) {
    return Column(
      children: [
        _buildTitleCard(),
        Expanded(child: _buildQuestionsPanel(context, provider)),
        _buildBottomBar(context, provider),
      ],
    );
  }

  // ── Left panel ──
  Widget _buildLeftPanel(BuildContext context, GameProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Quiz Details',
              style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildTitleInput(),
          const SizedBox(height: 32),
          // Stats card
          _StatsCard(questions: _questions),
          const Spacer(),
          // Action buttons
          _GradientButton(
            gradient: AppColors.gradBtnGreen,
            icon: Icons.play_arrow_rounded,
            label: 'Launch Session',
            enabled: _questions.isNotEmpty,
            onTap: () {
              if (_titleController.text.trim().isEmpty) {
                _showError('Enter quiz title');
                return;
              }
              provider.createSessionWithQuiz(
                _questions,
                title: _titleController.text.trim(),
              );
              context.push('/teacher/lobby');
            },
          ),
          const SizedBox(height: 12),
          _GradientButton(
            gradient: AppColors.gradBtn,
            icon: Icons.add_rounded,
            label: 'Add Question',
            onTap: _addQuestion,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: _buildTitleInput(),
    );
  }

  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(
          color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: 'Quiz Title',
        labelStyle:
            const TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w500),
        hintText: 'e.g. Science Chapter 4',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primaryLight, size: 20),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Questions panel ──
  Widget _buildQuestionsPanel(BuildContext context, GameProvider provider) {
    final isWide = MediaQuery.of(context).size.width > 800;

    if (_questions.isEmpty) {
      return _EmptyState(onAdd: _addQuestion);
    }

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _questions.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _questions.removeAt(oldIndex);
                _questions.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              return _QuestionCard(
                key: ValueKey(_questions[index]),
                question: _questions[index],
                index: index,
                typeColor: _typeColor(_questions[index].type),
                typeLabel: _typeLabel(_questions[index].type),
                typeIcon: _typeIcon(_questions[index].type),
                onEdit: () => _editQuestion(index),
                onDelete: () => _deleteQuestion(index),
              );
            },
          ),
        ),
        if (isWide) const SizedBox.shrink()
        else const SizedBox(height: 80), // space for bottom bar
      ],
    );
  }

  // ── Bottom bar (narrow only) ──
  Widget _buildBottomBar(BuildContext context, GameProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _GradientButton(
              gradient: AppColors.gradBtn,
              icon: Icons.add_rounded,
              label: 'Add Question',
              onTap: _addQuestion,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GradientButton(
              gradient: AppColors.gradBtnGreen,
              icon: Icons.play_arrow_rounded,
              label: 'Launch',
              enabled: _questions.isNotEmpty,
              onTap: () {
                if (_titleController.text.trim().isEmpty) {
                  _showError('Enter quiz title');
                  return;
                }
                provider.createSessionWithQuiz(
                  _questions,
                  title: _titleController.text.trim(),
                );
                context.push('/teacher/lobby');
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Card ───────────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final List<Question> questions;
  const _StatsCard({required this.questions});

  @override
  Widget build(BuildContext context) {
    final mcCount = questions.where((q) => q.type == QuestionType.multipleChoice).length;
    final ynCount = questions.where((q) => q.type == QuestionType.yesNo).length;
    final txCount = questions.where((q) => q.type == QuestionType.text).length;
    final totalPts = questions.fold<int>(0, (sum, q) => sum + q.points);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.gradCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview',
              style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1)),
          const SizedBox(height: 12),
          _StatRow(
              icon: Icons.quiz_rounded,
              label: 'Total Questions',
              value: '${questions.length}',
              color: AppColors.primary),
          _StatRow(
              icon: Icons.star_rounded,
              label: 'Total Points',
              value: '$totalPts',
              color: AppColors.warning),
          if (mcCount > 0)
            _StatRow(
                icon: Icons.checklist_rounded,
                label: 'Multiple Choice',
                value: '$mcCount',
                color: AppColors.primary),
          if (ynCount > 0)
            _StatRow(
                icon: Icons.thumbs_up_down_rounded,
                label: 'Yes / No',
                value: '$ynCount',
                color: AppColors.warning),
          if (txCount > 0)
            _StatRow(
                icon: Icons.edit_note_rounded,
                label: 'Text Answer',
                value: '$txCount',
                color: AppColors.accentLight),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSub, fontSize: 13))),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Question Card ────────────────────────────────────────────────────────────
class _QuestionCard extends StatelessWidget {
  final Question question;
  final int index;
  final Color typeColor;
  final String typeLabel;
  final IconData typeIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    Key? key,
    required this.question,
    required this.index,
    required this.typeColor,
    required this.typeLabel,
    required this.typeIcon,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: AppColors.gradCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle + number
            Column(
              children: [
                const Icon(Icons.drag_indicator_rounded,
                    color: AppColors.textMuted, size: 20),
                const SizedBox(height: 4),
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradBtn,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Text(
                    question.text,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Type badge
                  Row(
                    children: [
                      _TypeBadge(
                          color: typeColor, icon: typeIcon, label: typeLabel),
                      const SizedBox(width: 8),
                      _MetaBadge(
                          icon: Icons.timer_outlined,
                          label: '${question.timeLimit}s',
                          color: AppColors.textSub),
                      const SizedBox(width: 8),
                      _MetaBadge(
                          icon: Icons.star_outline_rounded,
                          label: '${question.points}',
                          color: AppColors.warning),
                    ],
                  ),
                  // Options preview (MC / YesNo)
                  if ((question.type == QuestionType.multipleChoice ||
                          question.type == QuestionType.yesNo) &&
                      question.options != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: question.options!
                            .asMap()
                            .entries
                            .map(
                              (e) => _OptionChip(
                                label:
                                    '${String.fromCharCode(65 + e.key)}) ${e.value}',
                                isCorrect: e.key == question.correctIndex,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            Column(
              children: [
                _IconBtn(
                    icon: Icons.edit_rounded,
                    color: AppColors.primary,
                    onTap: onEdit),
                const SizedBox(height: 4),
                _IconBtn(
                    icon: Icons.delete_rounded,
                    color: AppColors.danger,
                    onTap: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  const _TypeBadge(
      {required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MetaBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isCorrect;
  const _OptionChip({required this.label, required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withOpacity(0.15)
            : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isCorrect ? AppColors.success.withOpacity(0.5) : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCorrect)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.check_rounded,
                  color: AppColors.success, size: 11),
            ),
          Text(label,
              style: TextStyle(
                  color: isCorrect ? AppColors.success : AppColors.textSub,
                  fontSize: 11)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.accent.withOpacity(0.15)
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.quiz_outlined,
                color: AppColors.primaryLight.withOpacity(0.8), size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'No questions yet',
            style: TextStyle(
                color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Add Question" to start building your quiz',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _GradientButton(
            gradient: AppColors.gradBtn,
            icon: Icons.add_rounded,
            label: 'Add First Question',
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

// ─── Gradient Button ──────────────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final LinearGradient gradient;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _GradientButton({
    required this.gradient,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled ? gradient : null,
              color: enabled ? null : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── AppBar Action Button ─────────────────────────────────────────────────────
class _AppBarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _AppBarBtn(
      {required this.icon,
      required this.label,
      required this.gradient,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Question Edit Dialog ─────────────────────────────────────────────────────
class QuestionEditDialog extends StatefulWidget {
  final Question? question;
  const QuestionEditDialog({Key? key, this.question}) : super(key: key);

  @override
  State<QuestionEditDialog> createState() => _QuestionEditDialogState();
}

class _QuestionEditDialogState extends State<QuestionEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textController;
  late QuestionType _type;
  late List<TextEditingController> _optionControllers;
  late TextEditingController _correctAnswerTextController;
  late int _timeLimit;
  late int _points;
  int? _correctIndex;

  static const _timeLimits = [10, 20, 30, 45, 60, 90, 120];
  static const _pointOptions = [500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.question?.text ?? '');
    _type = widget.question?.type ?? QuestionType.multipleChoice;
    _optionControllers = List.generate(
      4,
      (i) => TextEditingController(
          text: widget.question?.options?.elementAtOrNull(i) ??
              (i == 0
                  ? 'Yes'
                  : i == 1
                      ? 'No'
                      : '')),
    );
    _correctAnswerTextController =
        TextEditingController(text: widget.question?.correctAnswerText ?? '');
    _timeLimit = widget.question?.timeLimit ?? 30;
    _points = widget.question?.points ?? 1000;
    _correctIndex = widget.question?.correctIndex ?? 0;
  }

  @override
  void dispose() {
    _textController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    _correctAnswerTextController.dispose();
    super.dispose();
  }

  InputDecoration _inputDec(String label, {String? hint, Widget? prefix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
            color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        prefixIcon: prefix,
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.gradBtn,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.question == null
                            ? Icons.add_rounded
                            : Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.question == null
                          ? 'Add Question'
                          : 'Edit Question',
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    _IconBtn(
                      icon: Icons.close_rounded,
                      color: AppColors.textMuted,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(height: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 16)),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question text
                        TextFormField(
                          controller: _textController,
                          style: const TextStyle(color: AppColors.text, fontSize: 15),
                          cursorColor: AppColors.primary,
                          maxLines: 3,
                          minLines: 1,
                          decoration: _inputDec('Question Text',
                              hint: 'e.g. What is the capital of France?',
                              prefix: const Icon(Icons.help_outline_rounded,
                                  color: AppColors.primaryLight, size: 18)),
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? 'Enter question' : null,
                        ),
                        const SizedBox(height: 16),
                        // Type selector
                        _SectionLabel(label: 'Question Type'),
                        const SizedBox(height: 8),
                        _TypeSelector(
                          selected: _type,
                          onChanged: (t) => setState(() => _type = t),
                        ),
                        const SizedBox(height: 16),
                        // Options
                        if (_type == QuestionType.multipleChoice ||
                            _type == QuestionType.yesNo) ...[
                          _SectionLabel(label: 'Answer Options  (tap to mark correct)'),
                          const SizedBox(height: 8),
                          ...List.generate(
                            _type == QuestionType.yesNo ? 2 : 4,
                            (i) => _OptionField(
                              controller: _optionControllers[i],
                              index: i,
                              isCorrect: _correctIndex == i,
                              label: _type == QuestionType.yesNo
                                  ? (i == 0 ? 'Yes' : 'No')
                                  : 'Option ${String.fromCharCode(65 + i)}',
                              onTap: () =>
                                  setState(() => _correctIndex = i),
                              dec: _inputDec(''),
                            ),
                          ),
                        ],
                        if (_type == QuestionType.text) ...[
                          _SectionLabel(label: 'Accepted Answers'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _correctAnswerTextController,
                            style: const TextStyle(color: AppColors.text),
                            cursorColor: AppColors.primary,
                            decoration: _inputDec(
                              'Keywords (comma-separated)',
                              hint: 'e.g. paris, france, capital',
                              prefix: const Icon(Icons.edit_note_rounded,
                                  color: AppColors.primaryLight, size: 18),
                            ),
                            validator: (v) => (v?.isEmpty ?? true)
                                ? 'Enter answer keywords'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                        // Time + Points
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionLabel(label: 'Time Limit'),
                                  const SizedBox(height: 8),
                                  _ChipSelector<int>(
                                    options: _timeLimits,
                                    selected: _timeLimit,
                                    label: (v) => '${v}s',
                                    onSelect: (v) =>
                                        setState(() => _timeLimit = v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionLabel(label: 'Points'),
                                  const SizedBox(height: 8),
                                  _ChipSelector<int>(
                                    options: _pointOptions,
                                    selected: _points,
                                    label: (v) => '$v',
                                    onSelect: (v) =>
                                        setState(() => _points = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Save button
                _GradientButton(
                  gradient: AppColors.gradBtn,
                  icon: Icons.check_rounded,
                  label: 'Save Question',
                  onTap: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final question = Question(
                        text: _textController.text.trim(),
                        type: _type,
                        options: (_type == QuestionType.multipleChoice ||
                                _type == QuestionType.yesNo)
                            ? _optionControllers
                                .map((c) => c.text.trim())
                                .where((t) => t.isNotEmpty)
                                .toList()
                            : null,
                        correctAnswerText: _type == QuestionType.text
                            ? _correctAnswerTextController.text.trim()
                            : null,
                        correctIndex: _correctIndex ?? 0,
                        points: _points,
                        timeLimit: _timeLimit,
                      );
                      Navigator.pop(context, question);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
  }
}

class _TypeSelector extends StatelessWidget {
  final QuestionType selected;
  final ValueChanged<QuestionType> onChanged;
  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = [
      (QuestionType.multipleChoice, Icons.checklist_rounded, 'Multiple Choice'),
      (QuestionType.yesNo, Icons.thumbs_up_down_rounded, 'Yes / No'),
      (QuestionType.text, Icons.edit_note_rounded, 'Text Answer'),
    ];
    return Row(
      children: types
          .map((t) => Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected == t.$1
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected == t.$1
                              ? AppColors.primary
                              : AppColors.border,
                          width: selected == t.$1 ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Icon(t.$2,
                            color: selected == t.$1
                                ? AppColors.primaryLight
                                : AppColors.textMuted,
                            size: 20),
                        const SizedBox(height: 4),
                        Text(
                          t.$3,
                          style: TextStyle(
                            color: selected == t.$1
                                ? AppColors.primaryLight
                                : AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _OptionField extends StatelessWidget {
  final TextEditingController controller;
  final int index;
  final bool isCorrect;
  final String label;
  final VoidCallback onTap;
  final InputDecoration dec;

  const _OptionField({
    required this.controller,
    required this.index,
    required this.isCorrect,
    required this.label,
    required this.onTap,
    required this.dec,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isCorrect ? AppColors.success.withOpacity(0.1) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isCorrect ? AppColors.success : AppColors.border,
              width: isCorrect ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              alignment: Alignment.center,
              child: isCorrect
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 20)
                  : Text(
                      String.fromCharCode(65 + index),
                      style: const TextStyle(
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w700),
                    ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
                cursorColor: AppColors.primary,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipSelector<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;
  const _ChipSelector(
      {required this.options,
      required this.selected,
      required this.label,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options
          .map((o) => GestureDetector(
                onTap: () => onSelect(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected == o
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected == o ? AppColors.primary : AppColors.border,
                        width: selected == o ? 2 : 1),
                  ),
                  child: Text(
                    label(o),
                    style: TextStyle(
                        color: selected == o ? AppColors.primaryLight : AppColors.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ))
          .toList(),
    );
  }
}