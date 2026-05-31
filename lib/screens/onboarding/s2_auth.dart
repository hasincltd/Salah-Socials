import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class S2Auth extends StatefulWidget {
  final bool initialSignIn; // true = show sign in form first
  final ValueNotifier<bool> signInModeNotifier;
  final void Function(bool isNewUser) onAuthSuccess;

  const S2Auth({
    super.key,
    required this.initialSignIn,
    required this.signInModeNotifier,
    required this.onAuthSuccess,
  });

  @override
  State<S2Auth> createState() => _S2AuthState();
}

class _S2AuthState extends State<S2Auth> {
  late bool _isSignIn;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isSignIn = widget.initialSignIn;
    widget.signInModeNotifier.addListener(_onModeChanged);
  }

  void _onModeChanged() {
    if (mounted) {
      setState(() => _isSignIn = widget.signInModeNotifier.value);
    }
  }

  @override
  void dispose() {
    widget.signInModeNotifier.removeListener(_onModeChanged);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      if (_isSignIn) {
        await AuthService.signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
        widget.onAuthSuccess(false);
      } else {
        await AuthService.signUpWithEmail(_emailCtrl.text, _passwordCtrl.text);
        widget.onAuthSuccess(true);
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null) {
        final isNew = result.additionalUserInfo?.isNewUser ?? false;
        widget.onAuthSuccess(isNew);
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleSignIn() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final result = await AuthService.signInWithApple();
      final isNew = result.additionalUserInfo?.isNewUser ?? false;
      widget.onAuthSuccess(isNew);
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email address first.');
      return;
    }
    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Password reset email sent to $email',
              style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
          backgroundColor: AppTheme.surface,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      setState(() => _errorMessage = _friendlyError(e.toString()));
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('user-not-found')) return 'No account found for this email.';
    if (raw.contains('weak-password')) {
      return 'Password must be at least 8 characters with a number.';
    }
    if (raw.contains('network-request-failed')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                _isSignIn ? 'Welcome back' : 'Create account',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isSignIn
                    ? 'Sign in to continue your journey'
                    : 'Join the community of mindful believers',
                style: GoogleFonts.outfit(
                    fontSize: 14, color: AppTheme.textSubtle),
              ),
              const SizedBox(height: 6),
              // Toggle
              Row(
                children: [
                  _ModeTab(
                    label: 'Sign Up',
                    selected: !_isSignIn,
                    onTap: () => setState(() => _isSignIn = false),
                  ),
                  const SizedBox(width: 10),
                  _ModeTab(
                    label: 'Sign In',
                    selected: _isSignIn,
                    onTap: () => setState(() => _isSignIn = true),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Email address',
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppTheme.textSubtle, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded,
                      color: AppTheme.textSubtle, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSubtle,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) return 'Minimum 8 characters';
                  if (!v.contains(RegExp(r'[0-9]'))) {
                    return 'Include at least one number';
                  }
                  return null;
                },
              ),
              if (!_isSignIn) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.textSubtle, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textSubtle,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
              if (_isSignIn) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 4),
                    ),
                    child: Text('Forgot password?',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ] else
                const SizedBox(height: 8),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: GoogleFonts.outfit(
                                fontSize: 13, color: AppTheme.error)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              // Primary action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.onPrimary,
                          ),
                        )
                      : Text(_isSignIn ? 'Sign In' : 'Create Account'),
                ),
              ),
              const SizedBox(height: 24),
              // OR divider
              Row(
                children: [
                  const Expanded(
                      child: Divider(color: Color(0xFF1F2D4A), thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('OR',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppTheme.textSubtle,
                            fontWeight: FontWeight.w500)),
                  ),
                  const Expanded(
                      child: Divider(color: Color(0xFF1F2D4A), thickness: 1)),
                ],
              ),
              const SizedBox(height: 20),
              // Apple SSO
              _SsoButton(
                onPressed: _loading ? null : _appleSignIn,
                icon: Icons.apple_rounded,
                label: 'Continue with Apple',
              ),
              const SizedBox(height: 12),
              // Google SSO
              _SsoButton(
                onPressed: _loading ? null : _googleSignIn,
                icon: Icons.g_mobiledata_rounded,
                label: 'Continue with Google',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFF1F2D4A),
            width: 1,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.primary : AppTheme.textSubtle)),
      ),
    );
  }
}

class _SsoButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _SsoButton(
      {required this.onPressed, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: AppTheme.textPrimary),
        label: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary)),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppTheme.surface,
          side: const BorderSide(color: Color(0xFF1F2D4A), width: 1),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
