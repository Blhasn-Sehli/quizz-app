import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/game_provider.dart';
import '../services/auth_service.dart';
import '../constants/app_theme.dart';
import '../widgets/theme_toggle.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          return isWide
              ? _WebLayout(constraints: constraints)
              : _MobileLayout();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MOBILE LAYOUT
// ─────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _MobileHero(),
          _BodySection(isWide: false),
        ],
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.tokens.bgDeep,
            context.tokens.surface,
            context.tokens.bg,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Glow top-right
            Positioned(
              top: -80, right: -80,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.tokens.primary.withOpacity(0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Glow bottom-left
            Positioned(
              bottom: 30, left: -60,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.tokens.accent.withOpacity(0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LiveBadge(),
                  const SizedBox(height: 22),
                  _HeroTitle(fontSize: 46),
                  const SizedBox(height: 10),
                  _HeroSubtitle(),
                  const SizedBox(height: 28),
                  _StatsRow(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WEB LAYOUT
// ─────────────────────────────────────────────
class _WebLayout extends StatelessWidget {
  final BoxConstraints constraints;
  const _WebLayout({required this.constraints});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _WebNav(),
          _WebHero(),
          _WebStatsBar(),
          _BodySection(isWide: true),
          _WebFooter(),
        ],
      ),
    );
  }
}

class _WebNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: t.bg.withOpacity(0.92),
        border: Border(
          bottom: BorderSide(color: t.border, width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(text: 'Quiz', style: TextStyle(color: t.text)),
                      TextSpan(text: 'App', style: TextStyle(color: t.primary)),
                    ],
                  ),
                ),
                const Spacer(),
                _LiveBadge(),
                const SizedBox(width: 16),
                const ThemeToggle(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.tokens.bgDeep,
            context.tokens.surfacePop,
            context.tokens.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  context.tokens.primary.withOpacity(0.18),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1140),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: text
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LiveBadge(),
                          const SizedBox(height: 28),
                          _HeroTitle(fontSize: 64),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) => Text(
                              'Real-time multiplayer quizzes.\nEngage your class, track results\nand make learning unforgettable.',
                              style: TextStyle(
                                fontSize: 17,
                                color: context.tokens.textSub,
                                height: 1.7,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Row(
                            children: [
                              Builder(
                                builder: (context) => _WebCTAButton(
                                  label: "I'm a Teacher",
                                  emoji: '🎓',
                                  gradient: [context.tokens.primaryDim, context.tokens.primary],
                                  onTap: () {}, // handled in role section
                                ),
                              ),
                              const SizedBox(width: 14),
                              Builder(
                                builder: (context) => _WebCTAButton(
                                  label: "I'm a Student",
                                  emoji: '🎮',
                                  gradient: [context.tokens.accentDim, context.tokens.accent],
                                  onTap: () => context.go(AppRoutes.studentJoin),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 60),
                    // Right: decorative card
                    Expanded(
                      flex: 4,
                      child: _WebHeroCard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebCTAButton extends StatelessWidget {
  final String label;
  final String emoji;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _WebCTAButton({
    required this.label,
    required this.emoji,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: context.tokens.success,
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (context) => Text(
                  'Live session',
                  style: TextStyle(fontSize: 12, color: context.tokens.success, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.tokens.text.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Builder(
                  builder: (context) => Text('PIN: 7382', style: TextStyle(color: context.tokens.text, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Builder(
            builder: (context) => Text('Science Quiz Ch.4', style: TextStyle(color: context.tokens.text, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
          _miniProgressBar('Biology', 0.82, context.tokens.primary),
          const SizedBox(height: 10),
          _miniProgressBar('Chemistry', 0.61, context.tokens.success),
          const SizedBox(height: 10),
          _miniProgressBar('Physics', 0.44, context.tokens.accent),
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.people_outline, color: context.tokens.primary, size: 16),
              const SizedBox(width: 6),
              Text('14 students joined', style: TextStyle(color: context.tokens.primary, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniProgressBar(String label, double value, Color color) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: context.tokens.textMuted)),
              Text('${(value * 100).round()}%', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 5,
              backgroundColor: context.tokens.text.withOpacity(0.07),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebStatsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tokens.surface,
        border: Border(
          top: BorderSide(color: context.tokens.border),
          bottom: BorderSide(color: context.tokens.border),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _WebStatItem(value: '2.4k', label: 'Quizzes created'),
                _WebStatDivider(),
                _WebStatItem(value: '18k', label: 'Active players'),
                _WebStatDivider(),
                _WebStatItem(value: '99%', label: 'Uptime'),
                _WebStatDivider(),
                _WebStatItem(value: '4.8★', label: 'Avg rating'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WebStatItem extends StatelessWidget {
  final String value;
  final String label;
  const _WebStatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        Text(value, style: TextStyle(fontFamily: 'sans-serif', fontSize: 28, fontWeight: FontWeight.w800, color: t.text, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: t.textMuted)),
      ],
    );
  }
}

class _WebStatDivider extends StatelessWidget {
  const _WebStatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: context.tokens.border.withOpacity(0.5));
  }
}

class _WebFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          '© 2025 QuizApp · Built for educators',
          style: TextStyle(fontSize: 12, color: context.tokens.textMuted),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED BODY SECTION
// ─────────────────────────────────────────────
class _BodySection extends StatelessWidget {
  final bool isWide;
  const _BodySection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isWide) ...[
            _WaveClipper2(),
            const SizedBox(height: 4),
            _FirebaseStatusRow(),
            const SizedBox(height: 24),
          ] else ...[
            const SizedBox(height: 32),
            _FirebaseStatusRow(),
            const SizedBox(height: 32),
          ],
          const Text(
            'CHOOSE YOUR ROLE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 2),
          ),
          const SizedBox(height: 14),
          _TeacherButton(),
          _OrDivider(),
          _StudentButton(),
        ],
      ),
    );

    if (isWide) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: content,
        ),
      );
    }
    return content;
  }
}

// ─────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.tokens.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: context.tokens.primary.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(),
          const SizedBox(width: 7),
          Builder(
            builder: (context) => Text(
              'Live quiz platform',
              style: TextStyle(color: context.tokens.text, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.04 * 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = Tween(begin: 1.0, end: 0.3).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.tokens.success,
        ),
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  final double fontSize;
  const _HeroTitle({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.05),
        children: [
          TextSpan(text: 'Quiz', style: TextStyle(color: t.text)),
          TextSpan(text: 'App', style: TextStyle(color: t.primary)),
        ],
      ),
    );
  }
}

class _HeroSubtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      'Real-time multiplayer quizzes.\nLearn, compete & win together.',
      style: TextStyle(fontSize: 15, color: t.textSub, height: 1.6),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _statCard('2.4k', 'Quizzes'),
        const SizedBox(width: 10),
        _statCard('18k', 'Players'),
        const SizedBox(width: 10),
        _statCard('99%', 'Uptime'),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Builder(
        builder: (context) {
          final t = context.tokens;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.border),
            ),
            child: Column(
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.text)),
                const SizedBox(height: 3),
                Text(label, style: TextStyle(fontSize: 10, color: t.textMuted, letterSpacing: 0.5)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WaveClipper2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ClipPath(
      clipper: _WaveShape(),
      child: Container(
        height: 28,
        color: t.primary.withOpacity(0.1),
      ),
    );
  }
}

class _WaveShape extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, 0);
    p.cubicTo(size.width * 0.25, size.height, size.width * 0.75, 0, size.width, size.height * 0.6);
    p.lineTo(size.width, size.height);
    p.lineTo(0, size.height);
    p.close();
    return p;
  }
  @override
  bool shouldReclip(_WaveShape old) => false;
}

class _FirebaseStatusRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final t = context.tokens;
        final connected = provider.isFirebaseConnected;
        final accent = connected ? t.success : t.warning;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: accent)),
              const SizedBox(width: 8),
              Text(
                connected ? 'Firebase connected' : 'Offline mode',
                style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  if (!connected) return;
                  try {
                    await FirebaseFirestore.instance
                        .collection('connection_test')
                        .doc('test_${DateTime.now().millisecondsSinceEpoch}')
                        .set({'timestamp': DateTime.now().toIso8601String()});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Firebase write successful!'),
                          backgroundColor: t.success,
                        ),
                      );
                    }
                  } catch (e) { debugPrint('Firebase test: $e'); }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withOpacity(0.25)),
                  ),
                  child: Text('Test', style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeacherButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Object?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final t = context.tokens;
        final isLoggedIn = snapshot.hasData && snapshot.data != null;
        return _RoleCard(
          emoji: '🎓',
          title: "I'm a Teacher",
          subtitle: 'Create & host quizzes',
          gradientColors: [t.primaryDim, t.primary],
          onTap: () => isLoggedIn
              ? context.go(AppRoutes.quizCreator)
              : context.go(AppRoutes.login),
        );
      },
    );
  }
}

class _StudentButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _RoleCard(
      emoji: '🎮',
      title: "I'm a Student",
      subtitle: 'Join with a PIN code',
      gradientColors: [t.accentDim, t.accent],
      onTap: () => context.go(AppRoutes.studentJoin),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _RoleCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Shine circle
              Positioned(
                top: -30, right: -30,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.text.withOpacity(0.06),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: t.text.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
                        const SizedBox(height: 3),
                        Text(widget.subtitle, style: TextStyle(fontSize: 12, color: t.text.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: t.text.withOpacity(0.15)),
                    child: Icon(Icons.chevron_right, color: t.text, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Builder(builder: (context) {
        final t = context.tokens;
        return Row(
          children: [
            Expanded(child: Container(height: 1, color: t.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(fontSize: 12, color: t.textMuted)),
            ),
            Expanded(child: Container(height: 1, color: t.border)),
          ],
        );
      }),
    );
  }
}