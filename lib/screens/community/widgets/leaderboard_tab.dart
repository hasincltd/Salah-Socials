part of '../community_screen.dart';

// ── Rank badge ────────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank == 1) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFD4A847), Color(0xFFF0C96A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            '1',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.onPrimary,
            ),
          ),
        ),
      );
    }
    if (rank == 2) {
      return Center(
        child: Text(
          '2',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFB0B8CC),
          ),
        ),
      );
    }
    if (rank == 3) {
      return Center(
        child: Text(
          '3',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFCD7F32),
          ),
        ),
      );
    }
    return Center(
      child: Text(
        '$rank',
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSubtle,
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const _Avatar({required this.name, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.20),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.outfit(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ── Prayer pips ───────────────────────────────────────────────────────────

class _PrayerPips extends StatelessWidget {
  final List<_PrayerState> states;
  const _PrayerPips({required this.states});

  static const _labels = ['F', 'D', 'A', 'M', 'I'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < states.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          _Pip(label: _labels[i], state: states[i]),
        ],
      ],
    );
  }
}

class _Pip extends StatelessWidget {
  final String label;
  final _PrayerState state;
  const _Pip({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final Color borderColor;

    switch (state) {
      case _PrayerState.done:
        bgColor     = const Color(0xFF22C55E).withValues(alpha: 0.18);
        borderColor = const Color(0xFF22C55E).withValues(alpha: 0.45);
        textColor   = const Color(0xFF22C55E);
      case _PrayerState.missed:
        bgColor     = const Color(0xFFFF6B6B).withValues(alpha: 0.14);
        borderColor = const Color(0xFFFF6B6B).withValues(alpha: 0.35);
        textColor   = const Color(0xFFFF6B6B);
      case _PrayerState.pending:
        bgColor     = const Color(0xFF1A2440);
        borderColor = const Color(0xFF283550);
        textColor   = AppTheme.textSubtle.withValues(alpha: 0.5);
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ── Streak badge ──────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  final int streak;
  final bool gold;
  const _StreakBadge({required this.streak, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: gold
            ? AppTheme.primary.withValues(alpha: 0.12)
            : const Color(0xFF1A2440),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: gold
              ? AppTheme.primary.withValues(alpha: 0.35)
              : const Color(0xFF283550),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$streak',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: gold ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
