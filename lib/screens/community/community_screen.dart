import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_avatar.dart';
import '../notifications/notifications_screen.dart';

part 'widgets/leaderboard_tab.dart';
part 'widgets/friend_row.dart';

// ── Data models ───────────────────────────────────────────────────────────

enum _PrayerState { done, missed, pending }

enum _Tab { active, allTime, myMosque, top100 }

class _Friend {
  final String id;
  final String name;
  final Color avatarColor;
  final List<_PrayerState> activePrayers;
  final List<_PrayerState> allTimePrayers;
  final List<_PrayerState> mosquePrayers;
  final int activeStreak; // Active Streak Count
  final int totalScore;   // Total Streak Score

  const _Friend({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.activePrayers,
    required this.allTimePrayers,
    required this.mosquePrayers,
    required this.activeStreak,
    required this.totalScore,
  });
}

class _NonFriend {
  final String id;
  final String name;
  final Color avatarColor;
  final int activeStreak;

  const _NonFriend({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.activeStreak,
  });
}

// Unified entry driving the leaderboard list for all tabs.
class _MixedEntry {
  final String id;
  final String name;
  final Color avatarColor;
  final int streak;
  final bool isFriend;
  final List<_PrayerState>? prayers; // null for non-friends

  const _MixedEntry({
    required this.id,
    required this.name,
    required this.avatarColor,
    required this.streak,
    required this.isFriend,
    this.prayers,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────

const _gold   = AppTheme.primary;
const _teal   = AppTheme.accent;
const _purple = Color(0xFF9B59F5);
const _orange = Color(0xFFFF8C42);
const _pink   = Color(0xFFEC4899);
const _blue   = Color(0xFF3B82F6);

const _friends = [
  _Friend(
    id: 'hasin',
    name: 'Hasin (You)',
    avatarColor: _gold,
    activePrayers: [
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
    activeStreak: 14,
    totalScore: 42,
  ),
  _Friend(
    id: 'adam',
    name: 'Adam K.',
    avatarColor: _teal,
    activePrayers: [
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
    activeStreak: 11,
    totalScore: 38,
  ),
  _Friend(
    id: 'ibrahim',
    name: 'Ibrahim S.',
    avatarColor: _purple,
    activePrayers: [
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
    activeStreak: 9,
    totalScore: 31,
  ),
  _Friend(
    id: 'omar',
    name: 'Omar R.',
    avatarColor: _orange,
    activePrayers: [
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
    activeStreak: 7,
    totalScore: 24,
  ),
  _Friend(
    id: 'yusuf',
    name: 'Yusuf M.',
    avatarColor: _blue,
    activePrayers: [
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
    activeStreak: 5,
    totalScore: 19,
  ),
  _Friend(
    id: 'zaid',
    name: 'Zaid H.',
    avatarColor: _pink,
    activePrayers: [
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
    activeStreak: 3,
    totalScore: 12,
  ),
];

// Non-friends at the same mosque — shown in My Mosque tab.
const _mosqueFriends = [
  _NonFriend(id: 'mq1', name: 'Abdullah T.', avatarColor: _purple, activeStreak: 8),
  _NonFriend(id: 'mq2', name: 'Khalid M.',   avatarColor: _blue,   activeStreak: 6),
  _NonFriend(id: 'mq3', name: 'Bilal A.',    avatarColor: _teal,   activeStreak: 2),
];

// Mock Top 100 non-friends for same country (UK default).
const _top100NonFriends = [
  _NonFriend(id: 'uk1',  name: 'Tariq N.',   avatarColor: _orange, activeStreak: 22),
  _NonFriend(id: 'uk2',  name: 'Farhan J.',  avatarColor: _pink,   activeStreak: 18),
  _NonFriend(id: 'uk3',  name: 'Salman R.',  avatarColor: _purple, activeStreak: 16),
  _NonFriend(id: 'uk4',  name: 'Nasser Y.',  avatarColor: _blue,   activeStreak: 13),
  _NonFriend(id: 'uk5',  name: 'Hamza K.',   avatarColor: _teal,   activeStreak: 10),
  _NonFriend(id: 'uk6',  name: 'Anas B.',    avatarColor: _orange, activeStreak: 8),
  _NonFriend(id: 'uk7',  name: 'Sufyan H.',  avatarColor: _pink,   activeStreak: 6),
  _NonFriend(id: 'uk8',  name: 'Idris T.',   avatarColor: _purple, activeStreak: 4),
  _NonFriend(id: 'uk9',  name: 'Musa K.',    avatarColor: _blue,   activeStreak: 2),
  _NonFriend(id: 'uk10', name: 'Dawud L.',   avatarColor: _teal,   activeStreak: 1),
];


// ── Screen ────────────────────────────────────────────────────────────────

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  _Tab _tab = _Tab.active;
  final Set<String> _sentRequests = {};
  int _myStreak = 0;
  int _myTotalScore = 0;

  @override
  void initState() {
    super.initState();
    _loadMyStats();
  }

  Future<void> _loadMyStats() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _myStreak     = _computeStreak(prefs);
      _myTotalScore = _computeTotalScore(prefs);
    });
  }

  int _computeStreak(SharedPreferences prefs) {
    const names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    String key(String dk, String n) => 'prayer_log_${dk}_$n';
    var day = DateTime.now();
    final todayDk = DateFormat('yyyy-MM-dd').format(day);
    if (!names.every((n) => prefs.getBool(key(todayDk, n)) == true)) {
      day = day.subtract(const Duration(days: 1));
    }
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final dk = DateFormat('yyyy-MM-dd').format(day);
      if (names.every((n) => prefs.getBool(key(dk, n)) == true)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _computeTotalScore(SharedPreferences prefs) {
    const names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final dates = <String>{};
    for (final k in prefs.getKeys()) {
      if (k.startsWith('prayer_log_')) {
        final parts = k.split('_');
        // key: prayer_log_YYYY-MM-DD_PrayerName → parts[2] = date
        if (parts.length == 4) dates.add(parts[2]);
      }
    }
    int total = 0;
    for (final dk in dates) {
      if (names.every((n) => prefs.getBool('prayer_log_${dk}_$n') == true)) {
        total++;
      }
    }
    return total;
  }

  // Real data for Hasin, mock for all other friends.
  int _activeStreak(_Friend f) => f.id == 'hasin' ? _myStreak     : f.activeStreak;
  int _totalScore(_Friend f)   => f.id == 'hasin' ? _myTotalScore : f.totalScore;

  // Build the ranked leaderboard entries for the active tab.
  List<_MixedEntry> get _ranked {
    final List<_MixedEntry> entries;

    switch (_tab) {
      case _Tab.active:
        entries = _friends.map((f) => _MixedEntry(
          id: f.id, name: f.name, avatarColor: f.avatarColor,
          streak: _activeStreak(f), isFriend: true, prayers: f.activePrayers,
        )).toList();

      case _Tab.allTime:
        entries = _friends.map((f) => _MixedEntry(
          id: f.id, name: f.name, avatarColor: f.avatarColor,
          streak: _totalScore(f), isFriend: true, prayers: f.allTimePrayers,
        )).toList();

      case _Tab.myMosque:
        entries = [
          ..._friends.map((f) => _MixedEntry(
            id: f.id, name: f.name, avatarColor: f.avatarColor,
            streak: _activeStreak(f), isFriend: true, prayers: f.mosquePrayers,
          )),
          ..._mosqueFriends.map((nf) => _MixedEntry(
            id: nf.id, name: nf.name, avatarColor: nf.avatarColor,
            streak: nf.activeStreak, isFriend: false,
          )),
        ];

      case _Tab.top100:
        entries = [
          ..._friends.map((f) => _MixedEntry(
            id: f.id, name: f.name, avatarColor: f.avatarColor,
            streak: _activeStreak(f), isFriend: true, prayers: f.activePrayers,
          )),
          ..._top100NonFriends.map((nf) => _MixedEntry(
            id: nf.id, name: nf.name, avatarColor: nf.avatarColor,
            streak: nf.activeStreak, isFriend: false,
          )),
        ];
    }

    entries.sort((a, b) => b.streak.compareTo(a.streak));
    return entries;
  }

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
                  border: Border.all(color: AppTheme.card, width: 1),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < ranked.length; i++)
                      ranked[i].isFriend
                          ? _FriendRow(
                              rank: i + 1,
                              entry: ranked[i],
                              isLast: i == ranked.length - 1,
                            )
                          : _NonFriendRow(
                              rank: i + 1,
                              entry: ranked[i],
                              isLast: i == ranked.length - 1,
                              requestSent: _sentRequests.contains(ranked[i].id),
                              onRequest: () => setState(() {
                                    if (_sentRequests.contains(ranked[i].id)) {
                                      _sentRequests.remove(ranked[i].id);
                                    } else {
                                      _sentRequests.add(ranked[i].id);
                                    }
                                  }),
                            ),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
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

  String get _subtitle => switch (tab) {
    _Tab.active   => "Your friends' active streaks",
    _Tab.allTime  => "Your friends' total scores",
    _Tab.myMosque => 'Friends and mosque community',
    _Tab.top100   => 'Top 100 · United Kingdom',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(bottom: BorderSide(color: AppTheme.card, width: 1)),
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
                          _subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: AppTheme.textSubtle,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const BellIconButton(),
                  const SizedBox(width: 4),
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
              // Tab pills — scrollable to handle 4 tabs on narrow screens.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TabPill(
                      label: 'Active',
                      selected: tab == _Tab.active,
                      onTap: () => onTabChanged(_Tab.active),
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
                    const SizedBox(width: 8),
                    _TabPill(
                      label: 'Top 100',
                      selected: tab == _Tab.top100,
                      onTap: () => onTabChanged(_Tab.top100),
                    ),
                  ],
                ),
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
