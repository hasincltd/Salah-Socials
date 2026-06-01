part of '../home_screen.dart';

// ── Streak Revive Dialog ──────────────────────────────────────────────────

class _StreakReviveDialog extends StatelessWidget {
  final int previousStreak;
  final int ssCoins;
  final int reviveCost;
  final VoidCallback onRevive;
  final VoidCallback onDismiss;

  const _StreakReviveDialog({
    required this.previousStreak,
    required this.ssCoins,
    required this.reviveCost,
    required this.onRevive,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = ssCoins >= reviveCost;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 14),
            Text(
              'Streak Revive Available',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'You missed a day, but your $previousStreak-day streak\ncan still be saved!',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSubtle,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StreakBubble(
                    count: previousStreak,
                    label: 'Before',
                    state: _BubbleState.active),
                _Arrow(),
                _StreakBubble(
                    count: 0,
                    label: 'Missed',
                    state: _BubbleState.missed),
                _Arrow(),
                _StreakBubble(
                    count: previousStreak,
                    label: 'Revived',
                    state: _BubbleState.revived),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 7),
                  Text(
                    'Balance: $ssCoins SS Coins',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAfford ? onRevive : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor:
                      AppTheme.primary.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  canAfford
                      ? 'Revive for $reviveCost SS Coins'
                      : 'Not enough SS Coins ($reviveCost needed)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: canAfford ? AppTheme.onPrimary : AppTheme.textSubtle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onDismiss,
              child: Text(
                'Maybe later',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSubtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BubbleState { active, missed, revived }

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.arrow_forward_rounded,
            size: 18, color: AppTheme.textSubtle.withValues(alpha: 0.5)),
      );
}

class _StreakBubble extends StatelessWidget {
  final int count;
  final String label;
  final _BubbleState state;

  const _StreakBubble({
    required this.count,
    required this.label,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (state) {
      case _BubbleState.active:
        color = AppTheme.primary;
      case _BubbleState.missed:
        color = AppTheme.textSubtle;
      case _BubbleState.revived:
        color = AppTheme.accent;
    }

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(
              color: color.withValues(
                  alpha: state == _BubbleState.missed ? 0.25 : 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
