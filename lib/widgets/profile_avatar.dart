import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Shared avatar widget used by the Home greeting row and My Profile screen.
// Both screens reference this single widget — swapping the painter or adding
// a real photo upload here updates both places automatically.

class ProfileAvatar extends StatelessWidget {
  final double size;

  const ProfileAvatar({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CustomPaint(
        painter: _AvatarPainter(),
        size: Size(size, size),
      ),
    );
  }
}

// ── Avatar painter — illustrated head + shoulders ─────────────────────────

class _AvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0E2A28),
    );

    final skin = Paint()..color = const Color(0xFFE8B89A);
    final hair = Paint()..color = const Color(0xFF3D2314);
    final top  = Paint()..color = AppTheme.accent;

    // Shoulders
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - 30, cy + 6, cx + 30, size.height + 8),
        const Radius.circular(14),
      ),
      top,
    );

    // Neck
    canvas.drawRect(
      Rect.fromLTRB(cx - 7, cy - 2, cx + 7, cy + 10),
      skin,
    );

    // Head
    final hR = size.width * 0.26;
    canvas.drawCircle(Offset(cx, cy - hR * 0.3), hR, skin);

    // Hair cap (top semicircle)
    final hairPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, cy - hR * 0.3), radius: hR * 1.01),
        math.pi, math.pi,
      )
      ..close();
    canvas.drawPath(hairPath, hair);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF2A1A0A);
    canvas.drawCircle(Offset(cx - 6, cy - hR * 0.25), 2.0, eyePaint);
    canvas.drawCircle(Offset(cx + 6, cy - hR * 0.25), 2.0, eyePaint);

    // Smile
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, cy - hR * 0.05), width: 11, height: 7),
      0, math.pi, false,
      Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => false;
}
