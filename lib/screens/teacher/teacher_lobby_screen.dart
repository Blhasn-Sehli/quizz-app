import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/game_provider.dart';
import '../../constants/app_colors.dart';

class TeacherLobbyScreen extends StatefulWidget {
  const TeacherLobbyScreen({Key? key}) : super(key: key);

  @override
  State<TeacherLobbyScreen> createState() => _TeacherLobbyScreenState();
}

class _TeacherLobbyScreenState extends State<TeacherLobbyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _pinCopied = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _copyPin(String pin) async {
    await Clipboard.setData(ClipboardData(text: pin));
    setState(() => _pinCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _pinCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final session = provider.session;

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar(context),
        body: _buildNoSession(),
      );
    }

    final studentCount = provider.students.length;
    final canStart = studentCount >= 2;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(context),
      body: isWide
          ? _buildWideLayout(context, provider, canStart, studentCount)
          : _buildNarrowLayout(context, provider, canStart, studentCount),
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
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              gradient: AppColors.gradBtn,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'Lobby',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.success.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text('LIVE',
                  style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Wide: two-column ──
  Widget _buildWideLayout(BuildContext context, GameProvider provider,
      bool canStart, int studentCount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel — fixed width, scrollable so nothing overflows vertically
        SizedBox(
          width: 300,
          child: Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPinCard(provider),
                  const SizedBox(height: 16),
                  _buildSessionInfo(provider),
                  const SizedBox(height: 16),
                  _buildStartButton(context, provider, canStart, studentCount),
                ],
              ),
            ),
          ),
        ),
        Container(width: 1, color: AppColors.border),
        // Right panel
        Expanded(child: _buildStudentsPanel(provider, studentCount)),
      ],
    );
  }

  // ── Narrow: stacked ──
  Widget _buildNarrowLayout(BuildContext context, GameProvider provider,
      bool canStart, int studentCount) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _buildPinCard(provider),
        ),
        Expanded(child: _buildStudentsPanel(provider, studentCount)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: _buildStartButton(context, provider, canStart, studentCount),
        ),
      ],
    );
  }

  // ── PIN Card ──
  // FIX 1: ClipRRect so decorative circles can't bleed outside the card
  // FIX 2: Wrap instead of Row for digits so they wrap on any panel width
  Widget _buildPinCard(GameProvider provider) {
    final pin = provider.currentPin ?? '-------';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.gradPin,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative bg circles — safely clipped by ClipRRect above
            Positioned(
              right: -28,
              top: -28,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.lock_open_rounded, color: Colors.white60, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'SESSION PIN',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Wrap prevents overflow when panel is narrow
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 6,
                    children: pin.split('').map((ch) => _PinDigit(digit: ch)).toList(),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _copyPin(pin),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _pinCopied
                            ? AppColors.success.withOpacity(0.25)
                            : Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _pinCopied
                              ? AppColors.success.withOpacity(0.6)
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _pinCopied ? Icons.check_rounded : Icons.copy_rounded,
                            color: _pinCopied ? AppColors.success : Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _pinCopied ? 'Copied!' : 'Copy PIN',
                            style: TextStyle(
                              color: _pinCopied ? AppColors.success : Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Share this PIN with your students',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Session Info ──
  Widget _buildSessionInfo(GameProvider provider) {
    final session = provider.session!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.gradCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SESSION INFO',
              style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1)),
          const SizedBox(height: 10),
          _InfoRow(
              icon: Icons.quiz_rounded,
              label: 'Quiz',
              value: session.quiz.title,
              color: AppColors.primary),
          _InfoRow(
              icon: Icons.help_outline_rounded,
              label: 'Questions',
              value: '${provider.session?.quiz.questions.length ?? 0}',
              color: AppColors.primaryLight),
          _InfoRow(
              icon: Icons.people_rounded,
              label: 'Students',
              value: '${provider.students.length}',
              color: AppColors.warning),
        ],
      ),
    );
  }

  // ── Students Panel ──
  Widget _buildStudentsPanel(GameProvider provider, int studentCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text('Students',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              _CountBadge(count: studentCount),
              const Spacer(),
              _RequirementChip(met: studentCount >= 2, count: studentCount),
            ],
          ),
        ),
        Expanded(
          child: provider.students.isEmpty
              ? _buildWaitingState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: provider.students.length,
                  itemBuilder: (context, index) {
                    final student = provider.students[index];
                    return _StudentTile(name: student.name, index: index);
                  },
                ),
        ),
      ],
    );
  }

  // ── Waiting State ──
  Widget _buildWaitingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Transform.scale(
              scale: _pulseAnim.value,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.accent.withOpacity(0.12),
                  ]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.group_add_rounded,
                    color: AppColors.primaryLight.withOpacity(0.7), size: 48),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Waiting for students…',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Share the PIN with your class to get started',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Start Button ──
  Widget _buildStartButton(BuildContext context, GameProvider provider,
      bool canStart, int studentCount) {
    return Opacity(
      opacity: canStart ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          gradient: canStart ? AppColors.gradBtnGreen : null,
          color: canStart ? null : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: canStart
              ? [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: canStart
                ? () {
                    provider.startGame();
                    context.go('/teacher/host');
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canStart
                        ? Icons.play_arrow_rounded
                        : Icons.hourglass_top_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      canStart
                          ? 'Start Game!'
                          : 'Need ${2 - studentCount} more student${(2 - studentCount) == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── No Session ──
  Widget _buildNoSession() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.danger, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('No Active Session',
              style: TextStyle(
                  color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Create a quiz first to start a session.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── PIN Digit ────────────────────────────────────────────────────────────────
class _PinDigit extends StatelessWidget {
  final String digit;
  const _PinDigit({required this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Count Badge ──────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.gradBtn,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count',
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Requirement Chip ─────────────────────────────────────────────────────────
class _RequirementChip extends StatelessWidget {
  final bool met;
  final int count;
  const _RequirementChip({required this.met, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            met ? 'Ready to start' : 'Min. 2 students',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Student Tile ─────────────────────────────────────────────────────────────
class _StudentTile extends StatelessWidget {
  final String name;
  final int index;
  const _StudentTile({required this.name, required this.index});

  Color _avatarColor(int i) {
    const colors = [
      Color(0xFF6366F1),
      Color(0xFF7C3AED),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
    ];
    return colors[i % colors.length];
  }

  String _initials(String n) {
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: AppColors.gradCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_initials(name),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Text('Joined',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.textSub, fontSize: 13))),
          Flexible(
            child: Text(value,
                style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}