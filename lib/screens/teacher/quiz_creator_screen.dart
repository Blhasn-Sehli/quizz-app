import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../models/question.dart';
import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/theme_toggle.dart';

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
  AppColorTokens get _t => context.tokens;

  LinearGradient get _gradBtn => LinearGradient(
        colors: [_t.primaryDim, _t.primary],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  LinearGradient get _gradBtnGreen => LinearGradient(
        colors: [_t.success.withOpacity(0.85), _t.success],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  LinearGradient get _gradCard => LinearGradient(
        colors: [_t.surface, _t.surfaceHigh],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  Color _typeColor(QuestionType t) => switch (t) {
        QuestionType.yesNo          => _t.warning,
        QuestionType.multipleChoice => _t.primary,
        QuestionType.text           => _t.accent,
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
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(color: Colors.white)),
          ]),
          backgroundColor: _t.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(color: Colors.white)),
          ]),
          backgroundColor: _t.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

  Future<void> _addQuestion() async {
    final result = await showDialog<Question>(
      context: context,
      barrierColor: _t.bgDeep.withOpacity(0.75),
      builder: (_) => const QuestionEditDialog(),
    );
    if (result != null) setState(() => _questions.add(result));
  }

  Future<void> _editQuestion(int index) async {
    final result = await showDialog<Question>(
      context: context,
      barrierColor: _t.bgDeep.withOpacity(0.75),
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
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: _buildAppBar(context, provider),
      body: isWide
          ? _buildWideLayout(context, provider)
          : _buildNarrowLayout(context, provider),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, GameProvider provider) {
    final t = context.tokens;
    return AppBar(
      backgroundColor: t.surface,
      elevation: 0,
      surfaceTintColor: t.surface.withOpacity(0.0),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: _gradBtn,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
      ),
      title: Text(
        'Quiz Creator',
        style: TextStyle(
          color: t.text,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: t.border),
      ),
      actions: [
        const ThemeToggle(),
        // Save
        _AppBarBtn(
          icon: Icons.save_rounded,
          label: 'Save',
          gradient: _gradBtn,
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
          color: t.surfaceHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.folder_open_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('Load', style: TextStyle(color: Colors.white, fontSize: 13)),
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
                PopupMenuItem<int>(
                  enabled: false,
                  child: Text('No saved quizzes',
                      style: TextStyle(color: t.textMuted)),
                ),
              ];
            }
            return quizzes
                .asMap()
                .entries
                .map((e) => PopupMenuItem<int>(
                      value: e.key,
                      child: Text(e.value.title,
                          style: TextStyle(color: t.text)),
                    ))
                .toList();
          },
        ),
        const SizedBox(width: 8),
        // History
        IconButton(
          icon: Icon(Icons.history_rounded, color: t.textSub),
          tooltip: 'Quiz History',
          onPressed: () => context.go(AppRoutes.quizHistory),
        ),
        // Logout
        IconButton(
          icon: Icon(Icons.logout_rounded, color: t.textSub),
          tooltip: 'Logout',
          onPressed: () async {
            try {
              await AuthService().signOut();
              if (mounted) context.go(AppRoutes.home);
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
            color: _t.surface,
            child: _buildLeftPanel(context, provider),
          ),
        ),
        Container(width: 1, color: _t.border),
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
          Text('Quiz Details',
              style: TextStyle(
                  color: _t.primaryGlow,
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
            gradient: _gradBtnGreen,
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
              context.go(AppRoutes.teacherLobby);
            },
          ),
          const SizedBox(height: 12),
          _GradientButton(
            gradient: _gradBtn,
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
      color: _t.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: _buildTitleInput(),
    );
  }

  Widget _buildTitleInput() {
    return TextField(
      controller: _titleController,
      style: TextStyle(
          color: _t.text, fontSize: 16, fontWeight: FontWeight.w600),
      cursorColor: _t.primary,
      decoration: InputDecoration(
        labelText: 'Quiz Title',
        labelStyle:
            TextStyle(color: _t.primaryGlow, fontSize: 13, fontWeight: FontWeight.w500),
        hintText: 'e.g. Science Chapter 4',
        hintStyle: TextStyle(color: _t.textMuted),
        prefixIcon: Icon(Icons.title_rounded, color: _t.primaryGlow, size: 20),
        filled: true,
        fillColor: _t.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: _t.primary, width: 2),
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
            buildDefaultDragHandles: false,
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
                dragHandle: ReorderableDragStartListener(
                  index: index,
                  child: _QuestionDragHandle(index: index),
                ),
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
        else const SizedBox(height: 80),
      ],
    );
  }

  // ── Bottom bar (narrow only) ──
  Widget _buildBottomBar(BuildContext context, GameProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _t.surface,
        border: Border(top: BorderSide(color: _t.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _GradientButton(
              gradient: _gradBtn,
              icon: Icons.add_rounded,
              label: 'Add Question',
              onTap: _addQuestion,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _GradientButton(
              gradient: _gradBtnGreen,
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
                context.go(AppRoutes.teacherLobby);
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
    final t = context.tokens;
    final mcCount = questions.where((q) => q.type == QuestionType.multipleChoice).length;
    final ynCount = questions.where((q) => q.type == QuestionType.yesNo).length;
    final txCount = questions.where((q) => q.type == QuestionType.text).length;
    final totalPts = questions.fold<int>(0, (sum, q) => sum + q.points);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.surface, t.surfaceHigh],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview',
              style: TextStyle(
                  color: t.primaryGlow,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1)),
          const SizedBox(height: 12),
          _StatRow(
              icon: Icons.quiz_rounded,
              label: 'Total Questions',
              value: '${questions.length}',
              color: t.primary),
          _StatRow(
              icon: Icons.star_rounded,
              label: 'Total Points',
              value: '$totalPts',
              color: t.warning),
          if (mcCount > 0)
            _StatRow(
                icon: Icons.checklist_rounded,
                label: 'Multiple Choice',
                value: '$mcCount',
                color: t.primary),
          if (ynCount > 0)
            _StatRow(
                icon: Icons.thumbs_up_down_rounded,
                label: 'Yes / No',
                value: '$ynCount',
                color: t.warning),
          if (txCount > 0)
            _StatRow(
                icon: Icons.edit_note_rounded,
                label: 'Text Answer',
                value: '$txCount',
                color: t.accent),
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
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: TextStyle(color: t.textSub, fontSize: 13))),
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
  final Widget dragHandle;
  final Color typeColor;
  final String typeLabel;
  final IconData typeIcon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    Key? key,
    required this.question,
    required this.index,
    required this.dragHandle,
    required this.typeColor,
    required this.typeLabel,
    required this.typeIcon,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final gradCard = LinearGradient(
      colors: [t.surface, t.surfaceHigh],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final actionIconSize = compact ? 16.0 : 18.0;
        final actionPadding = compact ? 7.0 : 8.0;

        final actionButtons = compact
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconBtn(
                    icon: Icons.edit_rounded,
                    color: t.primary,
                    onTap: onEdit,
                    iconSize: actionIconSize,
                    padding: actionPadding,
                  ),
                  const SizedBox(width: 8),
                  _IconBtn(
                    icon: Icons.delete_rounded,
                    color: t.danger,
                    onTap: onDelete,
                    iconSize: actionIconSize,
                    padding: actionPadding,
                  ),
                ],
              )
            : Column(
                children: [
                  _IconBtn(
                    icon: Icons.edit_rounded,
                    color: t.primary,
                    onTap: onEdit,
                    iconSize: actionIconSize,
                    padding: actionPadding,
                  ),
                  const SizedBox(height: 6),
                  _IconBtn(
                    icon: Icons.delete_rounded,
                    color: t.danger,
                    onTap: onDelete,
                    iconSize: actionIconSize,
                    padding: actionPadding,
                  ),
                ],
              );

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            gradient: gradCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dragHandle,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.text,
                        style: TextStyle(
                            color: t.text,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _TypeBadge(
                              color: typeColor,
                              icon: typeIcon,
                              label: typeLabel),
                          _MetaBadge(
                              icon: Icons.timer_outlined,
                              label: '${question.timeLimit}s',
                              color: t.textSub),
                          _MetaBadge(
                              icon: Icons.star_outline_rounded,
                              label: '${question.points}',
                              color: t.warning),
                        ],
                      ),
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
                      if (compact) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: actionButtons,
                        ),
                      ],
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  actionButtons,
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuestionDragHandle extends StatelessWidget {
  final int index;

  const _QuestionDragHandle({required this.index});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        Icon(Icons.drag_indicator_rounded, color: t.textMuted, size: 20),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [t.primaryDim, t.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
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
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCorrect
            ? t.success.withOpacity(0.15)
            : t.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isCorrect ? t.success.withOpacity(0.5) : t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCorrect)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.check_rounded, color: t.success, size: 11),
            ),
          Text(label,
              style: TextStyle(
                  color: isCorrect ? t.success : t.textSub,
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
  final double iconSize;
  final double padding;
  const _IconBtn(
      {required this.icon,
      required this.color,
      required this.onTap,
      this.iconSize = 16,
      this.padding = 6});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(icon, color: color, size: iconSize),
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
    final t = context.tokens;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  t.primary.withOpacity(0.15),
                  t.accent.withOpacity(0.15)
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.quiz_outlined,
                color: t.primaryGlow.withOpacity(0.8), size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'No questions yet',
            style: TextStyle(
                color: t.text, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Question" to start building your quiz',
            style: TextStyle(color: t.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _GradientButton(
            gradient: LinearGradient(
              colors: [t.primaryDim, t.primary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
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
    final t = context.tokens;
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
              color: enabled ? null : t.surfaceHigh,
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

  AppColorTokens get _t => context.tokens;

  LinearGradient get _gradBtn => LinearGradient(
        colors: [_t.primaryDim, _t.primary],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

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
        labelStyle: TextStyle(
            color: _t.primaryGlow, fontSize: 13, fontWeight: FontWeight.w500),
        hintStyle: TextStyle(color: _t.textMuted, fontSize: 13),
        prefixIcon: prefix,
        filled: true,
        fillColor: _t.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _t.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _t.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _t.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Dialog(
      backgroundColor: _t.surface,
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
                        gradient: _gradBtn,
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
                      style: TextStyle(
                          color: _t.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    _IconBtn(
                      icon: Icons.close_rounded,
                      color: _t.textMuted,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(height: 1, color: _t.border, margin: const EdgeInsets.symmetric(vertical: 16)),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question text
                        TextFormField(
                          controller: _textController,
                          style: TextStyle(color: _t.text, fontSize: 15),
                          cursorColor: _t.primary,
                          maxLines: 3,
                          minLines: 1,
                          decoration: _inputDec('Question Text',
                              hint: 'e.g. What is the capital of France?',
                              prefix: Icon(Icons.help_outline_rounded,
                                  color: _t.primaryGlow, size: 18)),
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
                            style: TextStyle(color: _t.text),
                            cursorColor: _t.primary,
                            decoration: _inputDec(
                              'Keywords (comma-separated)',
                              hint: 'e.g. paris, france, capital',
                              prefix: Icon(Icons.edit_note_rounded,
                                  color: _t.primaryGlow, size: 18),
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
                  gradient: _gradBtn,
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
    final t = context.tokens;
    return Text(label,
        style: TextStyle(
            color: t.primaryGlow,
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
    final t = context.tokens;
    final types = [
      (QuestionType.multipleChoice, Icons.checklist_rounded, 'Multiple Choice'),
      (QuestionType.yesNo, Icons.thumbs_up_down_rounded, 'Yes / No'),
      (QuestionType.text, Icons.edit_note_rounded, 'Text Answer'),
    ];
    return Row(
      children: types
          .map((type) => Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(type.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected == type.$1
                          ? t.primary.withOpacity(0.2)
                          : t.surfaceHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selected == type.$1
                              ? t.primary
                              : t.border,
                          width: selected == type.$1 ? 2 : 1),
                    ),
                    child: Column(
                      children: [
                        Icon(type.$2,
                            color: selected == type.$1
                                ? t.primaryGlow
                                : t.textMuted,
                            size: 20),
                        const SizedBox(height: 4),
                        Text(
                          type.$3,
                          style: TextStyle(
                            color: selected == type.$1
                                ? t.primaryGlow
                                : t.textMuted,
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
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isCorrect ? t.success.withOpacity(0.1) : t.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isCorrect ? t.success : t.border,
              width: isCorrect ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              alignment: Alignment.center,
              child: isCorrect
                  ? Icon(Icons.check_circle_rounded,
                      color: t.success, size: 20)
                  : Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                          color: t.textSub,
                          fontWeight: FontWeight.w700),
                    ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                style: TextStyle(color: t.text, fontSize: 14),
                cursorColor: t.primary,
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
    final t = context.tokens;
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
                        ? t.primary.withOpacity(0.2)
                        : t.surfaceHigh,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected == o ? t.primary : t.border,
                        width: selected == o ? 2 : 1),
                  ),
                  child: Text(
                    label(o),
                    style: TextStyle(
                        color: selected == o ? t.primaryGlow : t.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ))
          .toList(),
    );
  }
}