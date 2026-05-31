part of '../home_screen.dart';

// ── Streak chip ───────────────────────────────────────────────────────────

class _StreakChip extends StatelessWidget {
  final int streakDays;
  final int todayWeekday; // Dart: 1=Mon, 7=Sun
  final Map<int, bool> weekLogs; // weekday 1–7 → all 5 prayers logged

  const _StreakChip({
    required this.streakDays,
    required this.todayWeekday,
    required this.weekLogs,
  });

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2D4A)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '$streakDays',
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Day Streak',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _DayDot(
                  label: dayLabels[i],
                  dayNum: i + 1,
                  todayWeekday: todayWeekday,
                  isDone: weekLogs[i + 1] ?? false,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final int dayNum;
  final int todayWeekday;
  final bool isDone; // true only when all 5 prayers were logged that day

  const _DayDot({
    required this.label,
    required this.dayNum,
    required this.todayWeekday,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = dayNum == todayWeekday;

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: isToday
                ? AppTheme.primary
                : isDone
                    ? AppTheme.primary.withValues(alpha: 0.7)
                    : AppTheme.textSubtle.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppTheme.primary : Colors.transparent,
            border: isToday
                ? Border.all(color: AppTheme.primary, width: 2)
                : isDone
                    ? null
                    : Border.all(
                        color: AppTheme.textSubtle.withValues(alpha: 0.2),
                        width: 1),
          ),
          child: isDone
              ? const Icon(Icons.check_rounded,
                  size: 15, color: AppTheme.onPrimary)
              : isToday
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : null,
        ),
      ],
    );
  }
}
