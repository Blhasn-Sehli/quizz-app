import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignIn() async {
    setState(() { _errorMessage = null; _isLoading = true; });
    try {
      await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) context.go('/teacher/quiz-creator');
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Sign-in failed';
      if (e.code == 'user-not-found')        msg = 'No account found with this email.';
      else if (e.code == 'wrong-password')   msg = 'Wrong password. Please try again.';
      else if (e.code == 'invalid-email')    msg = 'Invalid email address.';
      else if (e.code == 'too-many-requests') msg = 'Too many attempts. Try again later.';
      else if (e.code == 'user-disabled')    msg = 'This account has been disabled.';
      else if (e.code == 'network-request-failed') msg = 'Network error. Check your connection.';
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      if (mounted) setState(() => _errorMessage = msg);
    } on Exception catch (e) {
      debugPrint('Sign-in error: $e');
      if (mounted) setState(() => _errorMessage = 'Sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email address first.');
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset email sent to $email'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on Exception {
      if (mounted) setState(() => _errorMessage = 'Failed to send reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          return isWide ? _buildWebLayout() : _buildMobileLayout();
        },
      ),
    );
  }

  // ── WEB LAYOUT ──────────────────────────────────────────
  Widget _buildWebLayout() {
    return Row(
      children: [
        // Left panel
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A0F3E), Color(0xFF0F3460), Color(0xFF0A1628)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Glow orbs
                Positioned(top: -80, right: -80, child: _glowOrb(300, const Color(0xFF6366F1), 0.15)),
                Positioned(bottom: -60, left: -60, child: _glowOrb(200, const Color(0xFF10B981), 0.1)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 13),
                                SizedBox(width: 6),
                                Text('Back', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Branding
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.05),
                            children: [
                              TextSpan(text: 'Quiz', style: TextStyle(color: Colors.white)),
                              TextSpan(text: 'App', style: TextStyle(color: Color(0xFF818CF8))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'The live quiz platform\nbuilt for educators.',
                          style: TextStyle(fontSize: 17, color: Color(0x73FFFFFF), height: 1.6),
                        ),
                        const SizedBox(height: 36),
                        // Feature pills
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: const [
                            _FeaturePill(icon: Icons.bolt, label: 'Real-time results'),
                            _FeaturePill(icon: Icons.people, label: 'Multiplayer'),
                            _FeaturePill(icon: Icons.bar_chart, label: 'Analytics'),
                          ],
                        ),
                        const Spacer(),
                        // Decorative card
                        _WebSideCard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right panel — form
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFF08080F),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildFormContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── MOBILE LAYOUT ────────────────────────────────────────
  Widget _buildMobileLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A0F3E), Color(0xFF0F3460), Color(0xFF0A1628)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -80, right: -80, child: _glowOrb(280, const Color(0xFF6366F1), 0.15)),
              Positioned(bottom: -60, left: -60, child: _glowOrb(200, const Color(0xFF10B981), 0.1)),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 12),
                              // Back
                              Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 13),
                                        SizedBox(width: 6),
                                        Text('Back', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Icon badge
                              Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8)),
                                  ],
                                ),
                                child: const Icon(Icons.school_rounded, color: Colors.white, size: 34),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Teacher Login',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Sign in to create and manage quizzes',
                                style: TextStyle(fontSize: 14, color: Color(0x73FFFFFF)),
                              ),
                              const SizedBox(height: 32),
                              _buildFormContent(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── FORM CONTENT (shared) ────────────────────────────────
  Widget _buildFormContent() {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isWide) ...[
          // Icon + heading for web right panel
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome back',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to your teacher account',
            style: TextStyle(fontSize: 14, color: Color(0x73FFFFFF)),
          ),
          const SizedBox(height: 32),
        ],

        // Error banner
        if (_errorMessage != null) ...[
          _ErrorBanner(message: _errorMessage!),
          const SizedBox(height: 16),
        ],

        // Email field
        _InputLabel(label: 'Email address'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _emailController,
          hint: 'you@school.edu',
          icon: Icons.email_outlined,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        // Password field
        _InputLabel(label: 'Password'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _passwordController,
          hint: '••••••••',
          icon: Icons.lock_outline,
          enabled: !_isLoading,
          obscureText: _obscurePassword,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: const Color(0xFF555577),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _isLoading ? null : _handleForgotPassword,
            child: const Text(
              'Forgot password?',
              style: TextStyle(fontSize: 13, color: Color(0xFF818CF8), fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Sign in button
        _SignInButton(isLoading: _isLoading, onTap: _isLoading ? null : _handleEmailSignIn),
        const SizedBox(height: 20),

        // Divider
        Row(
          children: [
            Expanded(child: Container(height: 1, color: const Color(0xFF1E1E38))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Text('or', style: TextStyle(fontSize: 12, color: Color(0xFF555577))),
            ),
            Expanded(child: Container(height: 1, color: const Color(0xFF1E1E38))),
          ],
        ),
        const SizedBox(height: 20),

        // Sign up link
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111124),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E1E38)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Don't have an account? ", style: TextStyle(color: Color(0x73FFFFFF), fontSize: 14)),
              GestureDetector(
                onTap: _isLoading ? null : () => context.push('/teacher/register'),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _glowOrb(double size, Color color, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF818CF8), letterSpacing: 0.5),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF818CF8),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555577), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF555577), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF111124),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E1E38)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1E1E38)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE24B4A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE24B4A).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE24B4A), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFFE24B4A), fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _SignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  const _SignInButton({required this.isLoading, this.onTap});

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null ? (_) { _ctrl.reverse(); widget.onTap!(); } : null,
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? const LinearGradient(colors: [Color(0xFF2D2A60), Color(0xFF3D2A60)])
                : const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isLoading ? [] : [
              BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Sign In', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF818CF8), size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _WebSideCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_user_outlined, color: Color(0xFF818CF8), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secure teacher accounts', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 3),
                Text('Protected by Firebase Auth', style: TextStyle(color: Color(0x73FFFFFF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}