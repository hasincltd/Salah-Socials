part of '../home_screen.dart';

// ── Hero prayer card ──────────────────────────────────────────────────────

class _HeroPrayerCard extends StatelessWidget {
  final _Prayer prayer;
  final String countdownStr;
  final String communityName;
  final AnimationController pulseAnim;

  const _HeroPrayerCard({
    required this.prayer,
    required this.countdownStr,
    required this.communityName,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(prayer.time);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface, Color(0xFF0D1525)],
        ),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.14),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(
              children: [
                Text(
                  'NEXT PRAYER',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prayer.name,
                  style: GoogleFonts.outfit(
                    fontSize: 44,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countdownStr,
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 3,
                  ).copyWith(
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Begins at $timeStr',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: AppTheme.textSubtle),
                ),
              ],
            ),
          ),
          // Community pulse strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: pulseAnim,
                  builder: (_, _) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent
                              .withValues(alpha: 0.65 * pulseAnim.value),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '47 people nearby just prayed $communityName',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
