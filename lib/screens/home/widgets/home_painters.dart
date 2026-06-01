part of '../home_screen.dart';

// ── Painters ──────────────────────────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarfieldPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in stars) {
      final phase = (t + s.phase) % 1.0;
      final opacity =
          s.maxOpacity * math.pow(math.sin(math.pi * phase), 2).toDouble();
      p.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.size, p);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter o) => o.t != t;
}

class _MosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.drawRect(Rect.fromLTWH(cx - 95, h * 0.52, 190, h * 0.48), p);

    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, h * 0.52), width: 136, height: 94),
      math.pi, math.pi, true, p,
    );

    for (final dx in [-62.0, 62.0]) {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx + dx, h * 0.60), width: 58, height: 42),
        math.pi, math.pi, true, p,
      );
    }

    for (final mx in [-132.0, 132.0]) {
      canvas.drawRect(Rect.fromLTWH(cx + mx - 6, h * 0.08, 12, h * 0.92), p);
      final tip = Path()
        ..moveTo(cx + mx - 10, h * 0.08)
        ..lineTo(cx + mx, 0)
        ..lineTo(cx + mx + 10, h * 0.08)
        ..close();
      canvas.drawPath(tip, p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.20);
    final r = size.width / 2;
    final outer = Path()
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(r + r * 0.52, r - r * 0.12), radius: r * 0.80));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
