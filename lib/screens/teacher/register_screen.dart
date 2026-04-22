import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _confirmPasswordController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  String? _validateInputs() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (email.isEmpty) return 'Please enter an email address.';
    if (!email.contains('@') || !email.contains('.')) return 'Please enter a valid email address.';
    if (password.isEmpty) return 'Please enter a password.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (password != confirm) return 'Passwords do not match.';
    return null;
  }

  Future<void> _handleRegister() async {
    final validationError = _validateInputs();
    if (validationError != null) { setState(() => _errorMessage = validationError); return; }
    setState(() { _errorMessage = null; _isLoading = true; });
    try {
      await _authService.registerWithEmail(_emailController.text.trim(), _passwordController.text);
      if (mounted) context.go(AppRoutes.quizCreator);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Registration failed';
      if (e.code == 'email-already-in-use') msg = 'Email already in use. Try signing in instead.';
      else if (e.code == 'weak-password') msg = 'Password too weak. Use at least 6 characters.';
      else if (e.code == 'invalid-email') msg = 'Invalid email address.';
      else if (e.code == 'operation-not-allowed') msg = 'Email/Password registration is not enabled.';
      else if (e.code == 'network-request-failed') msg = 'Network error. Check your connection.';
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      if (mounted) setState(() => _errorMessage = msg);
    } on Exception catch (e) {
      debugPrint('Registration error: $e');
      if (mounted) setState(() => _errorMessage = 'Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;
          return isWide ? _buildWebLayout() : _buildMobileLayout(constraints);
        },
      ),
    );
  }

  // ── WEB LAYOUT ──────────────────────────────────────────
  Widget _buildWebLayout() {
    return Row(
      children: [
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
                Positioned(top: -80, right: -80, child: _glowOrb(300, const Color(0xFF6366F1), 0.15)),
                Positioned(bottom: -60, left: -60, child: _glowOrb(200, const Color(0xFF818CF8), 0.1)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BackButton(onTap: () => context.go(AppRoutes.home)),
                        const Spacer(),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.05),
                            children: [
                              TextSpan(text: 'Join ', style: TextStyle(color: Colors.white)),
                              TextSpan(text: 'QuizApp', style: TextStyle(color: Color(0xFF818CF8))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Create your teacher account\nand start engaging your class\nin minutes.',
                          style: TextStyle(fontSize: 17, color: Color(0x73FFFFFF), height: 1.6),
                        ),
                        const SizedBox(height: 36),
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: const [
                            _FeaturePill(icon: Icons.flash_on, label: 'Free to start'),
                            _FeaturePill(icon: Icons.lock_outline, label: 'Secure account'),
                            _FeaturePill(icon: Icons.quiz_outlined, label: 'Unlimited quizzes'),
                          ],
                        ),
                        const Spacer(),
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
                    child: SlideTransition(position: _slideAnim, child: _buildFormContent(isWide: true)),
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
  Widget _buildMobileLayout(BoxConstraints outerConstraints) {
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
              Positioned(bottom: -60, left: -60, child: _glowOrb(200, const Color(0xFF818CF8), 0.1)),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight
                          - MediaQuery.of(context).padding.top
                          - MediaQuery.of(context).padding.bottom,
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
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _BackButton(onTap: () => context.go(AppRoutes.home)),
                              ),
                              const SizedBox(height: 32),
                              Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 8))],
                                ),
                                child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 34),
                              ),
                              const SizedBox(height: 20),
                              const Text('Create Account',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                              const SizedBox(height: 6),
                              const Text('Sign up to start creating quizzes',
                                  style: TextStyle(fontSize: 14, color: Color(0x73FFFFFF))),
                              const SizedBox(height: 32),
                              _buildFormContent(isWide: false),
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
  Widget _buildFormContent({required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isWide) ...[
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 20),
          const Text('Create your account',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('Join thousands of teachers on QuizApp',
              style: TextStyle(fontSize: 14, color: Color(0x73FFFFFF))),
          const SizedBox(height: 32),
        ],
        if (_errorMessage != null) ...[
          _ErrorBanner(message: _errorMessage!),
          const SizedBox(height: 16),
        ],
        const _InputLabel(label: 'Email address'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _emailController, hint: 'you@school.edu',
          icon: Icons.email_outlined, enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const _InputLabel(label: 'Password'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _passwordController, hint: 'At least 6 characters',
          icon: Icons.lock_outline, enabled: !_isLoading,
          obscureText: _obscurePassword,
          onChanged: (_) => setState(() {}),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF555577), size: 20),
          ),
        ),
        const SizedBox(height: 8),
        _PasswordStrengthHint(password: _passwordController.text),
        const SizedBox(height: 16),
        const _InputLabel(label: 'Confirm password'),
        const SizedBox(height: 8),
        _StyledTextField(
          controller: _confirmPasswordController, hint: 'Re-enter your password',
          icon: Icons.lock_person_outlined, enabled: !_isLoading,
          obscureText: _obscureConfirmPassword,
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            child: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF555577), size: 20),
          ),
        ),
        const SizedBox(height: 28),
        _CreateAccountButton(isLoading: _isLoading, onTap: _isLoading ? null : _handleRegister),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Container(height: 1, color: const Color(0xFF1E1E38))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('or', style: TextStyle(fontSize: 12, color: Color(0xFF555577)))),
            Expanded(child: Container(height: 1, color: const Color(0xFF1E1E38))),
          ],
        ),
        const SizedBox(height: 20),
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
              const Text('Already have an account? ', style: TextStyle(color: Color(0x73FFFFFF), fontSize: 14)),
              GestureDetector(
                onTap: _isLoading ? null : () => context.go(AppRoutes.login),
                child: const Text('Sign In',
                    style: TextStyle(color: Color(0xFF818CF8), fontWeight: FontWeight.w700, fontSize: 14)),
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

// ── PASSWORD STRENGTH ─────────────────────────────────────
class _PasswordStrengthHint extends StatelessWidget {
  final String password;
  const _PasswordStrengthHint({required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final len = password.length;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasNum = password.contains(RegExp(r'[0-9]'));
    int score = 0;
    if (len >= 6) score++;
    if (len >= 10) score++;
    if (hasUpper) score++;
    if (hasNum) score++;
    Color barColor;
    String label;
    if (score <= 1) { barColor = const Color(0xFFE24B4A); label = 'Weak'; }
    else if (score == 2) { barColor = const Color(0xFFF59E0B); label = 'Fair'; }
    else if (score == 3) { barColor = const Color(0xFF818CF8); label = 'Good'; }
    else { barColor = const Color(0xFFA78BFA); label = 'Strong'; }
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 4, minHeight: 3,
              backgroundColor: const Color(0xFF1E1E38),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 11, color: barColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── CREATE ACCOUNT BUTTON ─────────────────────────────────
class _CreateAccountButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;
  const _CreateAccountButton({required this.isLoading, this.onTap});

  @override
  State<_CreateAccountButton> createState() => _CreateAccountButtonState();
}

class _CreateAccountButtonState extends State<_CreateAccountButton>
    with SingleTickerProviderStateMixin {
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
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
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

// ── SHARED WIDGETS ────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            Text('Back to Home', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: Color(0xFF818CF8), letterSpacing: 0.5));
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
  final ValueChanged<String>? onChanged;

  const _StyledTextField({
    required this.controller, required this.hint, required this.icon,
    this.enabled = true, this.obscureText = false,
    this.keyboardType, this.suffixIcon, this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, enabled: enabled,
      obscureText: obscureText, keyboardType: keyboardType, onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: const Color(0xFF818CF8),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555577), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF555577), size: 20),
        suffixIcon: suffixIcon,
        filled: true, fillColor: const Color(0xFF111124),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E1E38))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1E1E38))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.04))),
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
          Expanded(child: Text(message,
              style: const TextStyle(color: Color(0xFFE24B4A), fontSize: 13, height: 1.4))),
        ],
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
            child: const Icon(Icons.workspace_premium_outlined, color: Color(0xFF818CF8), size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Free teacher account', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 3),
                Text('No credit card required', style: TextStyle(color: Color(0x73FFFFFF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}