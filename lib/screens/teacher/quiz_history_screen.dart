import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import 'package:quizz_app/models/question.dart';
import '../../providers/game_provider.dart';
import '../../models/quiz.dart';
import '../../constants/app_colors.dart';

// ─── Quiz History Screen ──────────────────────────────────────────────────────
class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({Key? key}) : super(key: key);

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;
  _SortOption _sort = _SortOption.newest;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-load quizzes for the logged-in teacher when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _searchQuery = query.toLowerCase());
    });
  }

  List<Quiz> _filterAndSort(List<Quiz> quizzes) {
    var list = quizzes.where((q) => q.id != null).toList();
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((q) => q.title.toLowerCase().contains(_searchQuery))
          .toList();
    }
    switch (_sort) {
      case _SortOption.newest:
        list.sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
        break;
      case _SortOption.oldest:
        list.sort((a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
        break;
      case _SortOption.mostPlayed:
        list.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case _SortOption.mostQuestions:
        list.sort(
            (a, b) => b.questions.length.compareTo(a.questions.length));
        break;
    }
    return list;
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final provider = Provider.of<GameProvider>(context, listen: false);
    await provider.loadSavedQuizzes();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _launch(Quiz quiz) async {
    final provider = Provider.of<GameProvider>(context, listen: false);
    try {
      await provider.playQuiz(quiz);
      if (mounted) context.go(AppRoutes.teacherLobby);
    } catch (e) {
      _showSnack('Failed to launch: $e', AppColors.danger);
    }
  }

  Future<void> _delete(Quiz quiz) async {
    if (quiz.id == null) {
      _showSnack('Quiz not saved to cloud.', Colors.blue);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (ctx) => _ConfirmDeleteDialog(title: quiz.title),
    );
    if (confirmed == true) {
      try {
        final provider = Provider.of<GameProvider>(context, listen: false);
        await provider.deleteSavedQuiz(quiz.id!);
        _showSnack('Quiz deleted', AppColors.success);
      } catch (e) {
        _showSnack('Failed to delete: $e', AppColors.danger);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final quizzes = _filterAndSort(provider.savedQuizzes);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSortBar(quizzes.length),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primaryLight,
                    backgroundColor: AppColors.surface,
                    child: quizzes.isEmpty
                        ? _buildEmptyState()
                        : isWide
                            ? _buildGrid(context, quizzes)
                            : _buildList(context, quizzes),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSub),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'My Quizzes',
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
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.textSub),
          tooltip: 'Refresh',
          onPressed: _refresh,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: AppColors.text, fontSize: 14),
        cursorColor: AppColors.primary,
        decoration: InputDecoration(
          hintText: 'Search quizzes…',
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.primaryLight, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSortBar(int count) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Text(
            '$count quiz${count == 1 ? '' : 'zes'}',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          const Text('Sort: ',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          _SortChip(
              label: 'Newest',
              selected: _sort == _SortOption.newest,
              onTap: () => setState(() => _sort = _SortOption.newest)),
          const SizedBox(width: 4),
          _SortChip(
              label: 'Most Played',
              selected: _sort == _SortOption.mostPlayed,
              onTap: () => setState(() => _sort = _SortOption.mostPlayed)),
          const SizedBox(width: 4),
          _SortChip(
              label: 'Longest',
              selected: _sort == _SortOption.mostQuestions,
              onTap: () => setState(() => _sort = _SortOption.mostQuestions)),
        ],
      ),
    );
  }

  // ── List (mobile) ──
  Widget _buildList(BuildContext context, List<Quiz> quizzes) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: quizzes.length,
      itemBuilder: (ctx, i) => _QuizCard(
        quiz: quizzes[i],
        onPlay: () => _launch(quizzes[i]),
        onDelete: () => _delete(quizzes[i]),
      ),
    );
  }

  // ── Grid (wide) ──
  Widget _buildGrid(BuildContext context, List<Quiz> quizzes) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: quizzes.length,
      itemBuilder: (ctx, i) => _QuizCard(
        quiz: quizzes[i],
        onPlay: () => _launch(quizzes[i]),
        onDelete: () => _delete(quizzes[i]),
        compact: false,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withOpacity(0.12),
                AppColors.accent.withOpacity(0.12),
              ]),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primaryLight,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading your quizzes…',
            style: TextStyle(
              color: AppColors.textSub,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withOpacity(0.12),
                AppColors.accent.withOpacity(0.12),
              ]),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.folder_open_rounded,
                color: AppColors.primaryLight.withOpacity(0.7), size: 52),
          ),
          const SizedBox(height: 20),
          const Text('No quizzes found',
              style: TextStyle(
                  color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try a different search term'
                : 'Create your first quiz to get started',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradBtn,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppRoutes.quizCreator),
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('New Quiz',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Quiz Card ────────────────────────────────────────────────────────────────
class _QuizCard extends StatelessWidget {
  final Quiz quiz;
  final VoidCallback onPlay;
  final VoidCallback onDelete;
  final bool compact;

  const _QuizCard({
    required this.quiz,
    required this.onPlay,
    required this.onDelete,
    this.compact = true,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _accentColor(int index) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF7C3AED),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final qCount = quiz.questions.length;
    final color = _accentColor(quiz.title.hashCode.abs());
    final mcCount = quiz.questions
        .where((q) => q.type == QuestionType.multipleChoice)
        .length;
    final ynCount =
        quiz.questions.where((q) => q.type == QuestionType.yesNo).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: AppColors.gradCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPlay,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Color avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$qCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1),
                      ),
                      const Text('Qs',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _InfoChip(
                              icon: Icons.calendar_today_rounded,
                              label: _formatDate(quiz.createdAt)),
                          if (quiz.playCount > 0)
                            _InfoChip(
                                icon: Icons.play_circle_outline_rounded,
                                label: '${quiz.playCount}× played',
                                color: color),
                          if (mcCount > 0)
                            _InfoChip(
                                icon: Icons.checklist_rounded,
                                label: '$mcCount MC'),
                          if (ynCount > 0)
                            _InfoChip(
                                icon: Icons.thumbs_up_down_rounded,
                                label: '$ynCount Y/N'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Actions
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionBtn(
                      icon: Icons.play_arrow_rounded,
                      color: AppColors.success,
                      tooltip: 'Launch',
                      onTap: onPlay,
                    ),
                    const SizedBox(height: 6),
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.danger,
                      tooltip: 'Delete',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon,
      required this.label,
      this.color = AppColors.textMuted});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }
}

// ─── Sort Chip ────────────────────────────────────────────────────────────────
enum _SortOption { newest, oldest, mostPlayed, mostQuestions }

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: selected ? AppColors.primaryLight : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Confirm Delete Dialog ────────────────────────────────────────────────────
class _ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  const _ConfirmDeleteDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Delete Quiz?',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '"$title" will be permanently deleted.',
              style: const TextStyle(color: AppColors.textSub, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSub,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text('Delete',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}