part of '../profile_screen.dart';

// ── Banner painter — vibrant Islamic geometric ────────────────────────────

class _BannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Rich gradient background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B3E),
            Color(0xFF08242A),
            Color(0xFF1A1040),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Grid of 8-pointed Islamic stars — gold fill
    final starFill = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.11)
      ..style = PaintingStyle.fill;
    final starStroke = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    const r = 20.0;
    const sp = 52.0;
    for (double x = sp / 2; x < size.width + sp; x += sp) {
      for (double y = sp / 2; y < size.height + sp; y += sp) {
        _star8(canvas, Offset(x, y), r, starFill);
        _star8(canvas, Offset(x, y), r, starStroke);
      }
    }

    // Offset row — teal accent stars (smaller)
    final tealFill = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    for (double x = sp; x < size.width + sp; x += sp) {
      for (double y = sp; y < size.height + sp; y += sp) {
        _star8(canvas, Offset(x, y), r * 0.45, tealFill);
      }
    }

    // Interlocking circle lattice
    final circlePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (double x = 0; x <= size.width + 36; x += 36) {
      for (double y = 0; y <= size.height + 36; y += 36) {
        canvas.drawCircle(Offset(x, y), 18, circlePaint);
      }
    }

    // Radial gold glow centre-right
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.6, -0.3),
          radius: 0.9,
          colors: [
            AppTheme.primary.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Teal glow left side
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, 0.4),
          radius: 0.7,
          colors: [
            AppTheme.accent.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Bottom fade to background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppTheme.background.withValues(alpha: 0.60)],
          stops: const [0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _star8(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    final inner = r * 0.42;
    for (int i = 0; i < 8; i++) {
      final oa = (i * math.pi / 4) - math.pi / 2;
      final ia = oa + math.pi / 8;
      final ox = c.dx + r * math.cos(oa);
      final oy = c.dy + r * math.sin(oa);
      final ix = c.dx + inner * math.cos(ia);
      final iy = c.dy + inner * math.sin(ia);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BannerPainter old) => false;
}
