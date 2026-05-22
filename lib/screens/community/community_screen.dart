import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

// ── Data models ───────────────────────────────────────────────────────────

enum _PrayerState { done, missed, pending }

class _Friend {
  final String id;
  final String name;
  final Color avatarColor;
  // prayers: [Fajr, Dhuhr, Asr, Maghrib, Isha]
  final List<_PrayerState> weekPrayers;
  final List<_PrayerState> allTimePrayers;
  final List<_PrayerState> mosquePrayers;
  final int weekStreak;
  final int allTimeStreak;
  final int mosqueStreak;

  const _Friend({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.weekPrayers,
    required this.allTimePrayers,
    required this.mosquePrayers,
    required this.weekStreak,
    required this.allTimeStreak,
    required this.mosqueStreak,
  });
}

enum _Tab { thisWeek, allTime, myMosque }

class _FeedItem {
  final IconData icon;
  final Color iconColor;
  final String boldName;
  final String text;
  final String time;

  const _FeedItem({
    required this.icon,
    required this.iconColor,
    required this.boldName,
    required this.text,
    required this.time,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────

const _gold   = Color(0xFFD4A847);
const _teal   = Color(0xFF2DD4A0);
const _purple = Color(0xFF9B59F5);
const _orange = Color(0xFFFF8C42);
const _pink   = Color(0xFFEC4899);
const _blue   = Color(0xFF3B82F6);

const _friends = [
  _Friend(
    id: 'hasin',
    name: 'Hasin (You)',
    avatarColor: _gold,
    weekPrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.done,
      _PrayerState.done, _PrayerState.done,
    ],
    allTimePrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.done,
      _PrayerState.done, _PrayerState.done,
    ],
    mosquePrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.missed,
      _PrayerState.done, _PrayerState.done,
    ],
    weekStreak: 14,
    allTimeStreak: 42,
    mosqueStreak: 7,
  ),
  _Friend(
    id: 'adam',
    name: 'Adam K.',
    avatarColor: _teal,
    weekPrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.missed,
      _PrayerState.done, _PrayerState.done,
    ],
    allTimePrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.done,
      _PrayerState.done, _PrayerState.missed,
    ],
    mosquePrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.done,
      _PrayerState.done, _PrayerState.pending,
    ],
    weekStreak: 11,
    allTimeStreak: 38,
    mosqueStreak: 12,
  ),
  _Friend(
    id: 'ibrahim',
    name: 'Ibrahim S.',
    avatarColor: _purple,
    weekPrayers: [
      _PrayerState.done, _PrayerState.missed, _PrayerState.done,
      _PrayerState.done, _PrayerState.done,
    ],
    allTimePrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.done,
      _PrayerState.missed, _PrayerState.done,
    ],
    mosquePrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.done,
      _PrayerState.done, _PrayerState.done,
    ],
    weekStreak: 9,
    allTimeStreak: 31,
    mosqueStreak: 9,
  ),
  _Friend(
    id: 'omar',
    name: 'Omar R.',
    avatarColor: _orange,
    weekPrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.done,
      _PrayerState.missed, _PrayerState.pending,
    ],
    allTimePrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.missed,
      _PrayerState.done, _PrayerState.done,
    ],
    mosquePrayers: [
      _PrayerState.done, _PrayerState.missed, _PrayerState.done,
      _PrayerState.done, _PrayerState.pending,
    ],
    weekStreak: 7,
    allTimeStreak: 24,
    mosqueStreak: 5,
  ),
  _Friend(
    id: 'yusuf',
    name: 'Yusuf M.',
    avatarColor: _blue,
    weekPrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.missed,
      _PrayerState.missed, _PrayerState.pending,
    ],
    allTimePrayers: [
      _PrayerState.done, _PrayerState.missed, _PrayerState.done,
      _PrayerState.done, _PrayerState.done,
    ],
    mosquePrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.missed,
      _PrayerState.done, _PrayerState.done,
    ],
    weekStreak: 5,
    allTimeStreak: 19,
    mosqueStreak: 6,
  ),
  _Friend(
    id: 'zaid',
    name: 'Zaid H.',
    avatarColor: _pink,
    weekPrayers: [
      _PrayerState.done, _PrayerState.missed, _PrayerState.missed,
      _PrayerState.done, _PrayerState.pending,
    ],
    allTimePrayers: [
      _PrayerState.missed, _PrayerState.done, _PrayerState.done,
      _PrayerState.done, _PrayerState.pending,
    ],
    mosquePrayers: [
      _PrayerState.done, _PrayerState.done, _PrayerState.done,
      _PrayerState.missed, _PrayerState.pending,
    ],
    weekStreak: 3,
    allTimeStreak: 12,
    mosqueStreak: 4,
  ),
];

final _feedItems = [
  _FeedItem(
    icon: Icons.local_fire_department_rounded,
    iconColor: _orange,
    boldName: 'Adam K.',
    text: ' hit a 10-day streak — keep going!',
    time: '2m ago',
  ),
  _FeedItem(
    icon: Icons.event_available_rounded,
    iconColor: _teal,
    boldName: 'Ibrahim S.',
    text: ' joined Quran Recitation Circle at Masjid Al-Noor',
    time: '18m ago',
  ),
  _FeedItem(
    icon: Icons.mosque_rounded,
    iconColor: _gold,
    boldName: 'Omar R.',
    text: ' prayed Jumu\'ah at East London Mosque',
    time: '1h ago',
  ),
  _FeedItem(
    icon: Icons.military_tech_rounded,
    iconColor: _purple,
    boldName: 'Yusuf M.',
    text: ' earned the "Night Owl" badge — 5 consecutive Isha prayers',
    time: '3h ago',
  ),
  _FeedItem(
    icon: Icons.local_fire_department_rounded,
    iconColor: _orange,
    boldName: 'Hasin',
    text: ' reached a 14-day streak — masha\'Allah!',
    time: '5h ago',
  ),
  _FeedItem(
    icon: Icons.people_rounded,
    iconColor: _blue,
    boldName: 'Zaid H.',
    text: ' joined the community — say salaam!',
    time: 'Yesterday',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  _Tab _tab = _Tab.thisWeek;

  List<_Friend> get _ranked {
    final sorted = [..._friends];
    sorted.sort((a, b) {
      final sa = _score(a), sb = _score(b);
      return sb.compareTo(sa);
    });
    return sorted;
  }

  int _score(_Friend f) {
    final prayers = switch (_tab) {
      _Tab.thisWeek  => f.weekPrayers,
      _Tab.allTime   => f.allTimePrayers,
      _Tab.myMosque  => f.mosquePrayers,
    };
    final streak = switch (_tab) {
      _Tab.thisWeek  => f.weekStreak,
      _Tab.allTime   => f.allTimeStreak,
      _Tab.myMosque  => f.mosqueStreak,
    };
    final done = prayers.where((p) => p == _PrayerState.done).length;
    return done * 10 + streak;
  }

  List<_PrayerState> _prayers(_Friend f) => switch (_tab) {
    _Tab.thisWeek  => f.weekPrayers,
    _Tab.allTime   => f.allTimePrayers,
    _Tab.myMosque  => f.mosquePrayers,
  };

  int _streak(_Friend f) => switch (_tab) {
    _Tab.thisWeek  => f.weekStreak,
    _Tab.allTime   => f.allTimeStreak,
    _Tab.myMosque  => f.mosqueStreak,
  };

  @override
  Widget build(BuildContext context) {
    final ranked = _ranked;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _Header(
              tab: _tab,
              onTabChanged: (t) => setState(() => _tab = t),
            ),
          ),
          // ── Leaderboard ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1A2440), width: 1),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < ranked.length; i++)
                      _FriendRow(
                        rank: i + 1,
                        friend: ranked[i],
                        prayers: _prayers(ranked[i]),
                        streak: _streak(ranked[i]),
                        isLast: i == ranked.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ),
          // ── Live feed divider ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: const Color(0xFF1A2440),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF22C55E),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Live Feed',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSubtle,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: const Color(0xFF1A2440),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Feed items ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FeedCard(item: _feedItems[i]),
                ),
                childCount: _feedItems.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final _Tab tab;
  final ValueChanged<_Tab> onTabChanged;

  const _Header({required this.tab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: Color(0xFF1A2440), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your friends this week',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppTheme.textSubtle,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Friend count chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: const Color(0xFF1F2D4A), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people_rounded,
                            size: 14, color: AppTheme.primary),
                        const SizedBox(width: 5),
                        Text(
                          '6 friends',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Tab pills
              Row(
                children: [
                  _TabPill(
                    label: 'This Week',
                    selected: tab == _Tab.thisWeek,
                    onTap: () => onTabChanged(_Tab.thisWeek),
                  ),
                  const SizedBox(width: 8),
                  _TabPill(
                    label: 'All Time',
                    selected: tab == _Tab.allTime,
                    onTap: () => onTabChanged(_Tab.allTime),
                  ),
                  const SizedBox(width: 8),
                  _TabPill(
                    label: 'My Mosque',
                    selected: tab == _Tab.myMosque,
                    onTap: () => onTabChanged(_Tab.myMosque),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab pill ──────────────────────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFF1F2D4A),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.onPrimary : AppTheme.textSubtle,
          ),
        ),
      ),
    );
  }
}

// ── Friend row ────────────────────────────────────────────────────────────

class _FriendRow extends StatelessWidget {
  final int rank;
  final _Friend friend;
  final List<_PrayerState> prayers;
  final int streak;
  final bool isLast;

  const _FriendRow({
    required this.rank,
    required this.friend,
    required this.prayers,
    required this.streak,
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
          _Avatar(
              name: friend.name, color: friend.avatarColor, size: 36),
          const SizedBox(width: 10),
          // Name + pips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                    color: isFirst
                        ? AppTheme.primary
                        : AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _PrayerPips(states: prayers),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Streak
          _StreakBadge(streak: streak, gold: isFirst),
        ],
      ),
    );
  }
}

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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
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

// ── Feed card ─────────────────────────────────────────────────────────────

class _FeedCard extends StatelessWidget {
  final _FeedItem item;
  const _FeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2440), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: item.iconColor.withValues(alpha: 0.25), width: 1),
            ),
            child: Icon(item.icon, size: 18, color: item.iconColor),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: item.boldName,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextSpan(text: item.text),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.time,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textSubtle.withValues(alpha: 0.6),
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
