part of '../profile_screen.dart';

// ── Salah Seasons tab ─────────────────────────────────────────────────────

class _SalahSeasonsTab extends StatelessWidget {
  const _SalahSeasonsTab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Winding path scene at 25% opacity
        Opacity(
          opacity: 0.25,
          child: SizedBox.expand(
            child: CustomPaint(painter: _SeasonPathPainter()),
          ),
        ),
        // Lock overlay — IgnorePointer so it doesn't block scroll events
        IgnorePointer(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 100,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming Soon',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Salah Seasons Launching Soon',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Season winding path painter ───────────────────────────────────────────

class _SeasonPathPainter extends CustomPainter {
  static const List<Offset> _nodes = [
    Offset(0.50, 0.93),
    Offset(0.25, 0.82),
    Offset(0.55, 0.71),
    Offset(0.75, 0.60),
    Offset(0.50, 0.49),
    Offset(0.25, 0.38),
    Offset(0.55, 0.27),
    Offset(0.75, 0.17),
    Offset(0.50, 0.08),
    Offset(0.50, 0.02),
  ];

  static const List<int> _milestoneValues = [
    5, 50, 150, 300, 500, 750, 1000, 1500, 2000, 2500
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawPath(canvas, size);
    for (int i = 0; i < _nodes.length; i++) {
      _drawNode(canvas, size, i);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Deep navy → dark purple gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0E3A), Color(0xFF0D1B3E)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final rng = math.Random(77);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (int i = 0; i < 70; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.2 + 0.3;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
    final goldPaint = Paint()..color = AppTheme.primary.withValues(alpha: 0.7);
    for (int i = 0; i < 10; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.8, goldPaint);
    }
  }

  void _drawPath(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final first = Offset(_nodes[0].dx * size.width, _nodes[0].dy * size.height);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < _nodes.length; i++) {
      path.lineTo(
        _nodes[i].dx * size.width,
        _nodes[i].dy * size.height,
      );
    }
    canvas.drawPath(path, pathPaint);
  }

  void _drawNode(Canvas canvas, Size size, int i) {
    final pos = Offset(_nodes[i].dx * size.width, _nodes[i].dy * size.height);
    const nodeR = 26.0;

    // Alternate gold / teal fill: odd = primary (gold), even = accent (teal)
    final fill = i.isOdd ? AppTheme.primary : AppTheme.accent;

    // Filled circle
    canvas.drawCircle(pos, nodeR, Paint()..color = fill);

    // White border ring
    canvas.drawCircle(
      pos, nodeR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Mini mosque silhouette in white
    _drawMiniMosque(canvas, pos, i);

    // Milestone label below node — white bold
    final tp = TextPainter(
      text: TextSpan(
        text: '${_milestoneValues[i]}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + nodeR + 4));
  }

  void _drawMiniMosque(Canvas canvas, Offset c, int tier) {
    // Scale 0.55–1.0 as tier increases; fits within nodeR=26
    final s = (0.55 + tier / 9.0 * 0.45) * 9.5;
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    // Left minaret
    canvas.drawRect(
      Rect.fromLTRB(c.dx - s * 1.7, c.dy - s * 1.1, c.dx - s * 1.0, c.dy + s * 0.3),
      p,
    );
    // Pointed minaret top
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s * 1.7, c.dy - s * 1.1)
        ..lineTo(c.dx - s * 1.35, c.dy - s * 1.75)
        ..lineTo(c.dx - s * 1.0, c.dy - s * 1.1)
        ..close(),
      p,
    );

    // Main building base
    canvas.drawRect(
      Rect.fromLTRB(c.dx - s * 0.85, c.dy - s * 0.25, c.dx + s * 0.85, c.dy + s * 0.5),
      p,
    );

    // Main dome
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy - s * 0.25),
        width: s * 1.3, height: s * 1.0,
      ),
      math.pi, math.pi, false, p,
    );

    // Crescent for higher tiers (tier ≥ 4)
    if (tier >= 4) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - s * 1.05),
          width: s * 0.5, height: s * 0.5,
        ),
        math.pi * 0.2, math.pi * 1.6, false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_SeasonPathPainter old) => false;
}
