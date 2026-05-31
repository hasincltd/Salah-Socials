part of '../profile_screen.dart';

// ── Stats row (Streak / SS Coins / Friends — all gold numbers) ────────────

class _StatsRow extends StatelessWidget {
  final int streakDays, ssCoins, friendsCount;
  const _StatsRow(
      {required this.streakDays,
      required this.ssCoins,
      required this.friendsCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(value: '$streakDays', label: 'Streak'),
        _StatItem(value: '$ssCoins', label: 'SS Coins'),
        _StatItem(value: '$friendsCount', label: 'Friends'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary)),
        const SizedBox(height: 1),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.textSubtle,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
