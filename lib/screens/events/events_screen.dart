import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

// ── Category enum ─────────────────────────────────────────────────────────

enum _Category { quran, youth, islamicStudy, sisters, community }

extension _CategoryX on _Category {
  String get label {
    switch (this) {
      case _Category.quran:        return 'Quran';
      case _Category.youth:        return 'Youth';
      case _Category.islamicStudy: return 'Islamic Study';
      case _Category.sisters:      return 'Sisters';
      case _Category.community:    return 'Community';
    }
  }

  Color get color {
    switch (this) {
      case _Category.quran:        return const Color(0xFF2DD4A0);
      case _Category.youth:        return const Color(0xFF9B59F5);
      case _Category.islamicStudy: return const Color(0xFFF59E0B);
      case _Category.sisters:      return const Color(0xFFEC4899);
      case _Category.community:    return const Color(0xFF3B82F6);
    }
  }
}

// ── Data model ────────────────────────────────────────────────────────────

class _Event {
  final String id;
  final String title;
  final String mosqueName;
  final _Category category;
  final bool isFree;
  final double distanceMi;
  final DateTime dateTime;
  final int attendees;
  final bool isFeatured;
  final List<Color> avatarColors;

  const _Event({
    required this.id,
    required this.title,
    required this.mosqueName,
    required this.category,
    required this.isFree,
    required this.distanceMi,
    required this.dateTime,
    required this.attendees,
    required this.isFeatured,
    required this.avatarColors,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────

List<_Event> _buildMockEvents() {
  final now = DateTime.now();
  return [
    _Event(
      id: '1',
      title: 'Quran Recitation Circle',
      mosqueName: 'Masjid Al-Noor',
      category: _Category.quran,
      isFree: true,
      distanceMi: 0.3,
      dateTime: DateTime(now.year, now.month, now.day, 20, 30)
          .add(const Duration(days: 0)),
      attendees: 24,
      isFeatured: true,
      avatarColors: [Color(0xFF2DD4A0), Color(0xFFD4A847), Color(0xFF9B59F5)],
    ),
    _Event(
      id: '2',
      title: 'Quran Memorisation Workshop',
      mosqueName: 'Masjid Al-Furqan',
      category: _Category.quran,
      isFree: true,
      distanceMi: 0.5,
      dateTime: DateTime(now.year, now.month, now.day, 18, 0)
          .add(const Duration(days: 1)),
      attendees: 15,
      isFeatured: false,
      avatarColors: [Color(0xFF3B82F6), Color(0xFFEC4899)],
    ),
    _Event(
      id: '3',
      title: 'Youth Weekly Halaqa',
      mosqueName: 'Islamic Society East',
      category: _Category.youth,
      isFree: true,
      distanceMi: 0.7,
      dateTime: DateTime(now.year, now.month, now.day, 19, 0)
          .add(const Duration(days: 2)),
      attendees: 18,
      isFeatured: false,
      avatarColors: [
        Color(0xFF9B59F5), Color(0xFF2DD4A0), Color(0xFFF59E0B)
      ],
    ),
    _Event(
      id: '4',
      title: 'Fiqh of Worship — Study Circle',
      mosqueName: 'East London Mosque',
      category: _Category.islamicStudy,
      isFree: true,
      distanceMi: 1.2,
      dateTime: DateTime(now.year, now.month, now.day, 18, 30)
          .add(const Duration(days: 3)),
      attendees: 31,
      isFeatured: true,
      avatarColors: [
        Color(0xFFF59E0B), Color(0xFF3B82F6), Color(0xFF2DD4A0),
        Color(0xFFEC4899)
      ],
    ),
    _Event(
      id: '5',
      title: 'Sisters Tafseer Gathering',
      mosqueName: 'Masjid Ibn Battuta',
      category: _Category.sisters,
      isFree: true,
      distanceMi: 1.6,
      dateTime: DateTime(now.year, now.month, now.day, 16, 0)
          .add(const Duration(days: 1)),
      attendees: 12,
      isFeatured: false,
      avatarColors: [Color(0xFFEC4899), Color(0xFF9B59F5)],
    ),
    _Event(
      id: '6',
      title: 'Community Iftar Night',
      mosqueName: 'Central Mosque',
      category: _Category.community,
      isFree: true,
      distanceMi: 2.8,
      dateTime: DateTime(now.year, now.month, now.day, 19, 45),
      attendees: 89,
      isFeatured: true,
      avatarColors: [
        Color(0xFF3B82F6), Color(0xFFD4A847), Color(0xFF2DD4A0),
        Color(0xFF9B59F5)
      ],
    ),
    _Event(
      id: '7',
      title: 'Youth Football & Dua Evening',
      mosqueName: 'Al-Rahma Community Centre',
      category: _Category.youth,
      isFree: true,
      distanceMi: 3.5,
      dateTime: DateTime(now.year, now.month, now.day, 15, 0)
          .add(const Duration(days: 4)),
      attendees: 22,
      isFeatured: false,
      avatarColors: [Color(0xFF9B59F5), Color(0xFFF59E0B)],
    ),
    _Event(
      id: '8',
      title: 'Sisters Self-Care & Sunnah',
      mosqueName: 'Dar Al-Salam Centre',
      category: _Category.sisters,
      isFree: true,
      distanceMi: 7.2,
      dateTime: DateTime(now.year, now.month, now.day, 13, 0)
          .add(const Duration(days: 5)),
      attendees: 19,
      isFeatured: false,
      avatarColors: [
        Color(0xFFEC4899), Color(0xFF2DD4A0), Color(0xFFD4A847)
      ],
    ),
  ];
}

final _allEvents = _buildMockEvents();

// ── Screen ────────────────────────────────────────────────────────────────

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  double _radiusMi = 2.0;
  final _joined = <String>{};
  final _attendeeOverrides = <String, int>{};

  static const _radii = [0.5, 2.0, 5.0, 10.0];

  List<_Event> get _filtered {
    return _allEvents.where((e) => e.distanceMi <= _radiusMi).toList()
      ..sort((a, b) {
        final d = a.distanceMi.compareTo(b.distanceMi);
        return d != 0 ? d : a.dateTime.compareTo(b.dateTime);
      });
  }

  int _count(_Event e) => _attendeeOverrides[e.id] ?? e.attendees;

  void _toggleJoin(_Event e) {
    setState(() {
      final c = _count(e);
      if (_joined.contains(e.id)) {
        _joined.remove(e.id);
        _attendeeOverrides[e.id] = c - 1;
      } else {
        _joined.add(e.id);
        _attendeeOverrides[e.id] = c + 1;
      }
    });
  }

  String _distLabel(double d) =>
      d < 0.1 ? '${(d * 5280).round()} ft' : '${d.toStringAsFixed(1)} mi';

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(dt.year, dt.month, dt.day).difference(today).inDays;
    final dayStr = diff == 0
        ? 'Today'
        : diff == 1
            ? 'Tomorrow'
            : DateFormat('EEE, d MMM').format(dt);
    return '$dayStr · ${DateFormat('h:mm a').format(dt)}';
  }

  @override
  Widget build(BuildContext context) {
    final events = _filtered;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _Header(
            radii: _radii,
            selected: _radiusMi,
            onSelect: (r) => setState(() => _radiusMi = r),
          ),
          Expanded(
            child: events.isEmpty
                ? _EmptyState(
                    onExpand: () => setState(() => _radiusMi = _radii.last),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: events.length,
                    itemBuilder: (context, i) {
                      final e = events[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EventCard(
                          event: e,
                          joined: _joined.contains(e.id),
                          attendeeCount: _count(e),
                          distLabel: _distLabel(e.distanceMi),
                          dateLabel: _dateLabel(e.dateTime),
                          onJoin: () => _toggleJoin(e),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final List<double> radii;
  final double selected;
  final ValueChanged<double> onSelect;

  const _Header({
    required this.radii,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: Color(0xFF1A2440), width: 1),
        ),
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
                    child: Text(
                      'Nearby Events',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1F2D4A)),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppTheme.textSubtle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Radius:',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.textSubtle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ...radii.map((r) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Pill(
                      label: r < 1 ? '${r}mi' : '${r.toInt()}mi',
                      selected: r == selected,
                      onTap: () => onSelect(r),
                    ),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Radius pill ───────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
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

// ── Event card ────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final _Event event;
  final bool joined;
  final int attendeeCount;
  final String distLabel;
  final String dateLabel;
  final VoidCallback onJoin;

  const _EventCard({
    required this.event,
    required this.joined,
    required this.attendeeCount,
    required this.distLabel,
    required this.dateLabel,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2440), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gold spotlight strip for featured events
            if (event.isFeatured)
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFD4A847), Color(0xFFF0C96A), Color(0xFFD4A847)],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: category + free badge + featured label + distance
                  Row(
                    children: [
                      _CategoryTag(category: event.category),
                      const SizedBox(width: 7),
                      if (event.isFree) const _FreeBadge(),
                      if (event.isFeatured) ...[
                        const SizedBox(width: 7),
                        _SpotlightBadge(),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: AppTheme.textSubtle,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        distLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSubtle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    event.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mosque name
                  Row(
                    children: [
                      Icon(
                        Icons.mosque_outlined,
                        size: 13,
                        color: AppTheme.primary.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        event.mosqueName,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSubtle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Date & time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppTheme.textSubtle.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dateLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSubtle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Bottom row: avatar stack + count + join
                  Row(
                    children: [
                      _AvatarStack(colors: event.avatarColors),
                      const SizedBox(width: 8),
                      Text(
                        '$attendeeCount attending',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSubtle,
                        ),
                      ),
                      const Spacer(),
                      _JoinButton(joined: joined, onTap: onJoin),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category tag ──────────────────────────────────────────────────────────

class _CategoryTag extends StatelessWidget {
  final _Category category;
  const _CategoryTag({required this.category});

  @override
  Widget build(BuildContext context) {
    final col = category.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        category.label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: col,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Free badge ────────────────────────────────────────────────────────────

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    const col = Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        'FREE',
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: col,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Spotlight badge ───────────────────────────────────────────────────────

class _SpotlightBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 10, color: AppTheme.primary),
          const SizedBox(width: 3),
          Text(
            'Spotlight',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar stack ──────────────────────────────────────────────────────────

class _AvatarStack extends StatelessWidget {
  final List<Color> colors;
  const _AvatarStack({required this.colors});

  @override
  Widget build(BuildContext context) {
    final count = colors.length.clamp(0, 4);
    final width = 22.0 + (count - 1) * 16.0;
    return SizedBox(
      width: width.clamp(22.0, double.infinity),
      height: 24,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: i * 16.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i],
                  border: Border.all(
                      color: AppTheme.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Join button ───────────────────────────────────────────────────────────

class _JoinButton extends StatelessWidget {
  final bool joined;
  final VoidCallback onTap;

  const _JoinButton({required this.joined, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF22C55E);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: joined
              ? green.withValues(alpha: 0.13)
              : AppTheme.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: joined
                ? green.withValues(alpha: 0.45)
                : AppTheme.primary,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: joined
              ? [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: green),
                  const SizedBox(width: 5),
                  Text(
                    'Joined',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: green,
                    ),
                  ),
                ]
              : [
                  Text(
                    'Join',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onPrimary,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onExpand;
  const _EmptyState({required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              border: Border.all(color: const Color(0xFF1A2440), width: 1.5),
            ),
            child: Icon(
              Icons.event_outlined,
              size: 34,
              color: AppTheme.primary.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No events nearby',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try expanding your radius',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSubtle,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onExpand,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Text(
                'Expand to 10 mi',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
