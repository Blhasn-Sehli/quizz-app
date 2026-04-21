import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import '../../providers/game_provider.dart';
import '../../constants/app_colors.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({Key? key}) : super(key: key);

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen>
    with SingleTickerProviderStateMixin {
  // One controller per PIN digit
  final List<TextEditingController> _digitControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocusNodes =
      List.generate(6, (_) => FocusNode());

  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  String? _pinError;
  String? _nameError;
  bool _isLoading = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocusNodes) {
      f.dispose();
    }
    _nameController.dispose();
    _nameFocus.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  String get _pin =>
      _digitControllers.map((c) => c.text).join();

  void _onDigitChanged(String value, int index) {
    if (value.length == 1) {
      // Move to next digit
      if (index < 5) {
        _digitFocusNodes[index + 1].requestFocus();
      } else {
        // Last digit filled — move to name
        _nameFocus.requestFocus();
      }
    }
    setState(() => _pinError = null);
  }

  void _onDigitBackspace(int index) {
    if (_digitControllers[index].text.isEmpty && index > 0) {
      _digitControllers[index - 1].clear();
      _digitFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _validateAndJoin() async {
    final pin = _pin;
    final name = _nameController.text.trim();

    bool hasError = false;

    if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      setState(() => _pinError = 'Enter a valid 6-digit PIN');
      hasError = true;
    }
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter your nickname');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<GameProvider>(context, listen: false);
    try {
      await provider.studentJoin(pin, name);
      if (mounted) {
        context.go(AppRoutes.studentLobby, extra: {'pin': pin, 'name': name});
      }
    } catch (e) {
      setState(() {
        _pinError = e.toString().contains('Invalid PIN')
            ? 'Invalid PIN. Please check and try again.'
            : 'Failed to join: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background decorative blobs
          _buildBackground(),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 0 : 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _buildCard(isWide),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ──
  Widget _buildBackground() {
    return Stack(
      children: [
        // Top-left blob
        Positioned(
          left: -80,
          top: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom-right blob
        Positioned(
          right: -60,
          bottom: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Center subtle blob
        Positioned(
          right: 80,
          top: 120,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryLight.withOpacity(0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Main Card ──
  Widget _buildCard(bool isWide) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo + title
            _buildHeader(),
            const SizedBox(height: 36),
            // PIN section
            _buildSectionLabel('Game PIN'),
            const SizedBox(height: 10),
            _buildPinInput(),
            if (_pinError != null) ...[
              const SizedBox(height: 6),
              _buildErrorText(_pinError!),
            ],
            const SizedBox(height: 24),
            // Nickname section
            _buildSectionLabel('Your Nickname'),
            const SizedBox(height: 10),
            _buildNameInput(),
            if (_nameError != null) ...[
              const SizedBox(height: 6),
              _buildErrorText(_nameError!),
            ],
            const SizedBox(height: 32),
            // Join button
            _buildJoinButton(),
            const SizedBox(height: 20),
            // Footer hint
            const Text(
              'Ask your teacher for the PIN to join the session',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Column(
      children: [
        // Icon with gradient ring
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.gradBtn,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Join a Game',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter your PIN and nickname to play',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ── Section Label ──
  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.primaryLight,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── PIN Input — 6 individual digit boxes ──
  Widget _buildPinInput() {
    return Row(
      children: List.generate(6 * 2 - 1, (index) {
        if (index.isOdd) {
          return const SizedBox(width: 8);
        }

        final i = index ~/ 2;
        final hasError = _pinError != null;
        final isFilled = _digitControllers[i].text.isNotEmpty;

        return Expanded(
          child: SizedBox(
            height: 56,
            child: _DigitBox(
              controller: _digitControllers[i],
              focusNode: _digitFocusNodes[i],
              hasError: hasError,
              isFilled: isFilled,
              onChanged: (v) => _onDigitChanged(v, i),
              onBackspace: () => _onDigitBackspace(i),
            ),
          ),
        );
      }),
    );
  }

  // ── Name Input ──
  Widget _buildNameInput() {
    return TextField(
      controller: _nameController,
      focusNode: _nameFocus,
      style: const TextStyle(
          color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w600),
      cursorColor: AppColors.primary,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _validateAndJoin(),
      onChanged: (_) => setState(() => _nameError = null),
      decoration: InputDecoration(
        hintText: 'e.g. Alex, SuperPlayer…',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.person_rounded,
            color: AppColors.primaryLight, size: 20),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _nameError != null ? AppColors.danger : AppColors.border,
            width: _nameError != null ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _nameError != null ? AppColors.danger : AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Error Text ──
  Widget _buildErrorText(String msg) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            color: AppColors.danger, size: 14),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(
                color: AppColors.danger,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ── Join Button ──
  Widget _buildJoinButton() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: _isLoading ? null : AppColors.gradBtnGreen,
        color: _isLoading ? AppColors.surfaceHigh : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isLoading ? null : _validateAndJoin,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch_rounded,
                          color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Join Game',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Single Digit Input Box ───────────────────────────────────────────────────
class _DigitBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final bool isFilled;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _DigitBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.isFilled,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<_DigitBox> createState() => _DigitBoxState();
}

class _DigitBoxState extends State<_DigitBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? AppColors.danger
        : _focused
            ? AppColors.primary
            : widget.isFilled
                ? AppColors.primaryLight.withOpacity(0.6)
                : AppColors.border;

    final bgColor = widget.isFilled
        ? AppColors.primary.withOpacity(0.12)
        : AppColors.surfaceHigh;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: _focused || widget.hasError ? 2 : 1.5,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            widget.onBackspace();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: TextStyle(
            color: widget.isFilled ? AppColors.primaryLight : AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          cursorColor: AppColors.primary,
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}