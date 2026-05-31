import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class S1Welcome extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const S1Welcome({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD4A847), Color(0xFFC4922A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: CustomPaint(painter: _MosqueLogoPainter()),
            ),
            const SizedBox(height: 32),
            // App name
            Text(
              'Salah Socials',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            // Arabic subtitle
            Text(
              'صلاة مجتمع',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // Tagline
            Text(
              'Pray together.\nStay connected.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSubtle,
                height: 1.5,
              ),
            ),
            const Spacer(flex: 3),
            // Get started
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onGetStarted,
                child: const Text('Get Started'),
              ),
            ),
            const SizedBox(height: 16),
            // Already have account
            TextButton(
              onPressed: onSignIn,
              child: Text(
                'I already have an account',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSubtle,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Minimal mosque silhouette for the logo circle
class _MosqueLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.onPrimary.withValues(alpha: 0.92)
      ..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Main dome
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 4), width: 38, height: 32),
      math.pi, math.pi, false, p,
    );
    // Main body
    canvas.drawRect(Rect.fromLTRB(cx - 19, cy - 4, cx + 19, cy + 18), p);

    // Left minaret
    canvas.drawRect(Rect.fromLTRB(cx - 32, cy - 14, cx - 24, cy + 18), p);
    canvas.drawPath(
      Path()
        ..moveTo(cx - 32, cy - 14)
        ..lineTo(cx - 28, cy - 24)
        ..lineTo(cx - 24, cy - 14)
        ..close(),
      p,
    );

    // Right minaret
    canvas.drawRect(Rect.fromLTRB(cx + 24, cy - 14, cx + 32, cy + 18), p);
    canvas.drawPath(
      Path()
        ..moveTo(cx + 24, cy - 14)
        ..lineTo(cx + 28, cy - 24)
        ..lineTo(cx + 32, cy - 14)
        ..close(),
      p,
    );

    // Crescent on dome
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy - 18), width: 11, height: 11),
      math.pi * 0.15, math.pi * 1.7, false,
      Paint()
        ..color = AppTheme.onPrimary.withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(_MosqueLogoPainter old) => false;
}
