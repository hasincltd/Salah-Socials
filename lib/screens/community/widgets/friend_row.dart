part of '../community_screen.dart';

// ── Friend leaderboard row ────────────────────────────────────────────────

class _FriendRow extends StatelessWidget {
  final int rank;
  final _MixedEntry entry;
  final bool isLast;

  const _FriendRow({
    required this.rank,
    required this.entry,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isFirst
            ? AppTheme.primary.withValues(alpha: 0.06)
            : Colors.transparent,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(18))
            : rank == 1
                ? const BorderRadius.vertical(top: Radius.circular(18))
                : BorderRadius.zero,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFF192036), width: 0.5),
              ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: _RankBadge(rank: rank),
          ),
          const SizedBox(width: 10),
          // Avatar
          _Avatar(name: entry.name, color: entry.avatarColor, size: 36),
          const SizedBox(width: 10),
          // Name + prayer pips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                    color: isFirst ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _PrayerPips(states: entry.prayers!),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Streak
          _StreakBadge(streak: entry.streak, gold: isFirst),
        ],
      ),
    );
  }
}

// ── Non-friend leaderboard row ────────────────────────────────────────────

class _NonFriendRow extends StatelessWidget {
  final int rank;
  final _MixedEntry entry;
  final bool isLast;
  final bool requestSent;
  final VoidCallback onRequest;

  const _NonFriendRow({
    required this.rank,
    required this.entry,
    required this.isLast,
    required this.requestSent,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(18))
            : rank == 1
                ? const BorderRadius.vertical(top: Radius.circular(18))
                : BorderRadius.zero,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFF192036), width: 0.5),
              ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: _RankBadge(rank: rank),
          ),
          const SizedBox(width: 10),
          // Avatar
          _Avatar(name: entry.name, color: entry.avatarColor, size: 36),
          const SizedBox(width: 10),
          // Name only (limited view for non-friends)
          Expanded(
            child: Text(
              entry.name,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Friend request button — greyed until tapped, then gold.
          GestureDetector(
            onTap: onRequest,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: requestSent
                    ? AppTheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: requestSent
                      ? AppTheme.primary
                      : AppTheme.textSubtle.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                requestSent ? 'Request Sent' : '+ Add Friend',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: requestSent ? AppTheme.primary : AppTheme.textSubtle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
