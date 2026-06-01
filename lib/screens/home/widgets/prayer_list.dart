part of '../home_screen.dart';

// ── Prayer list ───────────────────────────────────────────────────────────

class _PrayerListCard extends StatelessWidget {
  final List<_Prayer> prayers;
  final AnimationController pulseAnim;
  final Map<String, bool> prayerLogs;
  final void Function(String) onToggle;
  final bool isToday;
  final bool isPremiumRetroactive;
  final bool isFuture;

  const _PrayerListCard({
    required this.prayers,
    required this.pulseAnim,
    required this.prayerLogs,
    required this.onToggle,
    this.isToday = true,
    this.isPremiumRetroactive = false,
    this.isFuture = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2D4A)),
      ),
      child: Column(
        children: List.generate(prayers.length, (i) {
          // Window is open only on today when the prayer has started AND
          // the next prayer hasn't started yet.
          final windowOpen = isToday &&
              !prayers[i].time.isAfter(now) &&
              (i == prayers.length - 1 || prayers[i + 1].time.isAfter(now));
          final isCompleted = isToday
              ? (!prayers[i].time.isAfter(now) && !windowOpen)
              : isFuture
                  ? false
                  : true;
          return _PrayerRow(
            prayer: prayers[i],
            isCurrent: windowOpen,
            isCompleted: isCompleted,
            isLogged: prayerLogs[prayers[i].name] ?? false,
            isLast: i == prayers.length - 1,
            onTap: (windowOpen || isPremiumRetroactive)
                ? () => onToggle(prayers[i].name)
                : null,
            pulseAnim: pulseAnim,
          );
        }),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final _Prayer prayer;
  final bool isCurrent, isCompleted, isLogged, isLast;
  final VoidCallback? onTap;
  final AnimationController pulseAnim;

  const _PrayerRow({
    required this.prayer,
    required this.isCurrent,
    required this.isCompleted,
    required this.isLogged,
    required this.isLast,
    this.onTap,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(prayer.time);
    final Widget row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrent
            ? (isLogged
                ? AppTheme.accent.withValues(alpha: 0.08)
                : AppTheme.primary.withValues(alpha: 0.08))
            : Colors.transparent,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : BorderRadius.zero,
        border: isLast
            ? null
            : const Border(
                bottom:
                    BorderSide(color: Color(0xFF192036), width: 0.5)),
      ),
      child: Row(
        children: [
          // Dot — pulsing when window open (gold unlogged, green logged); coloured otherwise.
          if (isCurrent)
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, _) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLogged ? AppTheme.accent : AppTheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (isLogged ? AppTheme.accent : AppTheme.primary)
                          .withValues(alpha: 0.75 * pulseAnim.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: prayer.dot,
              ),
            ),
          const SizedBox(width: 14),
          // Name
          Expanded(
            child: Text(
              prayer.name,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCurrent
                    ? (isLogged ? AppTheme.accent : AppTheme.primary)
                    : AppTheme.textPrimary,
              ),
            ),
          ),
          // Time
          Text(
            timeStr,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isCurrent
                  ? (isLogged ? AppTheme.accent : AppTheme.primary)
                  : AppTheme.textSubtle,
            ),
          ),
          const SizedBox(width: 12),
          // Log circle — four distinct states.
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLogged
                    ? Colors.green.withValues(alpha: 0.18)
                    : Colors.transparent,
                border: Border.all(
                  color: isLogged
                      ? Colors.green
                      : isCurrent
                          ? AppTheme.primary
                          : isCompleted
                              ? AppTheme.textSubtle
                              : const Color(0xFF1F2D4A),
                  width: 1.5,
                ),
              ),
              child: isLogged
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.green)
                  : null,
            ),
          ),
        ],
      ),
    );

    // State 1a: logged AND window still open → full opacity (prayer in progress).
    // State 1b: logged AND window closed → 50% opacity (prayer complete).
    if (isLogged && !isCurrent) return Opacity(opacity: 0.5, child: row);
    // State 3: missed (window closed, not logged) → 40% opacity.
    if (isCompleted) return Opacity(opacity: 0.4, child: row);
    // State 2 (current) and state 4 (future) → full opacity.
    return row;
  }
}
