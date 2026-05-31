import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class S3Profile extends StatefulWidget {
  final void Function(String username, String displayName) onNext;

  const S3Profile({super.key, required this.onNext});

  @override
  State<S3Profile> createState() => _S3ProfileState();
}

class _S3ProfileState extends State<S3Profile> {
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _UsernameStatus _usernameStatus = _UsernameStatus.idle;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.addListener(_onUsernameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.removeListener(_onUsernameChanged);
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _debounce?.cancel();
    final val = _usernameCtrl.text.trim().toLowerCase();
    if (val.isEmpty || val.length < 3) {
      setState(() => _usernameStatus = _UsernameStatus.idle);
      return;
    }
    setState(() => _usernameStatus = _UsernameStatus.checking);
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      // Format validation only (Firestore uniqueness check requires backend)
      final valid = RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(val);
      setState(() {
        _usernameStatus =
            valid ? _UsernameStatus.available : _UsernameStatus.invalid;
      });
    });
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_usernameStatus != _UsernameStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please choose a valid username (3–20 chars, a–z 0–9 _)',
            style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    widget.onNext(
      _usernameCtrl.text.trim().toLowerCase(),
      _displayNameCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Your Profile',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'How should the community know you?',
                style: GoogleFonts.outfit(
                    fontSize: 14, color: AppTheme.textSubtle),
              ),
              const SizedBox(height: 28),
              // Avatar placeholder
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.surface,
                        border: Border.all(
                            color: const Color(0xFF1F2D4A), width: 2),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 44, color: AppTheme.textSubtle),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                          border: Border.all(
                              color: AppTheme.background, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 14, color: AppTheme.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'You can update this anytime',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AppTheme.textSubtle),
                ),
              ),
              const SizedBox(height: 28),
              // Username field
              TextFormField(
                controller: _usernameCtrl,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'username',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 6),
                    child: Text('@',
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  suffixIcon: _buildUsernameStatusIcon(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Username is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 6),
              _buildUsernameHint(),
              const SizedBox(height: 16),
              // Display name field
              TextFormField(
                controller: _displayNameCtrl,
                textInputAction: TextInputAction.done,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Display name',
                  prefixIcon: Icon(Icons.badge_outlined,
                      color: AppTheme.textSubtle, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: const Text('Next'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameStatusIcon() {
    switch (_usernameStatus) {
      case _UsernameStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.textSubtle),
          ),
        );
      case _UsernameStatus.available:
        return const Icon(Icons.check_circle_rounded,
            color: Color(0xFF22C55E), size: 20);
      case _UsernameStatus.invalid:
        return const Icon(Icons.cancel_rounded, color: AppTheme.error, size: 20);
      case _UsernameStatus.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUsernameHint() {
    switch (_usernameStatus) {
      case _UsernameStatus.available:
        return Text('Username is available',
            style: GoogleFonts.outfit(
                fontSize: 11, color: const Color(0xFF22C55E)));
      case _UsernameStatus.invalid:
        return Text('3–20 characters, letters, numbers and _ only',
            style:
                GoogleFonts.outfit(fontSize: 11, color: AppTheme.error));
      default:
        return Text('3–20 characters, letters, numbers and _ only',
            style: GoogleFonts.outfit(
                fontSize: 11, color: AppTheme.textSubtle));
    }
  }
}

enum _UsernameStatus { idle, checking, available, invalid }
