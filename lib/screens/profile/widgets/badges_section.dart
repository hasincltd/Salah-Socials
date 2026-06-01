part of '../profile_screen.dart';

// ── Badges section ────────────────────────────────────────────────────────

class _BadgeData {
  final IconData icon;
  final String name;
  final String criteria;
  final bool isPremium;
  const _BadgeData(this.icon, this.name, this.criteria,
      {this.isPremium = false});
}

const _kCoreBadges = <_BadgeData>[
  _BadgeData(Icons.mosque_rounded,                'First Prayer',      'Complete your first prayer'),
  _BadgeData(Icons.home_rounded,                  'Full House',        'All 5 prayers in one day'),
  _BadgeData(Icons.local_fire_department_rounded, 'Week One',          '7-day active streak'),
  _BadgeData(Icons.wb_twilight_rounded,           'Fajr Warrior',      '7 consecutive Fajr prayers'),
  _BadgeData(Icons.wb_sunny_rounded,              'Dawn Guardian',     'Fajr at dawn for 7 days'),
  _BadgeData(Icons.access_time_rounded,           'Dhuhr Devotee',     '7 consecutive Dhuhr prayers'),
  _BadgeData(Icons.anchor,                        'Afternoon Anchor',  '7 consecutive Asr prayers'),
  _BadgeData(Icons.flare,                         'Golden Hour',       '7 consecutive Maghrib prayers'),
  _BadgeData(Icons.nightlight_round,              'Night Owl',         '7 consecutive Isha prayers'),
  _BadgeData(Icons.trending_up_rounded,           'Comeback Kid',      'Rebuild streak to 7 in 14 days'),
  _BadgeData(Icons.flight_rounded,                'Traveler',          'Pray in 3 different cities'),
  _BadgeData(Icons.groups_rounded,                'Community Pillar',  'Attend 5 mosque events'),
  _BadgeData(Icons.emoji_events_rounded,          'Monthly Champion',  '30-day active streak'),
];

const _kPremiumBadges = <_BadgeData>[
  _BadgeData(Icons.brightness_3,          'Ramadan Hero',      'All prayers every day of Ramadan',    isPremium: true),
  _BadgeData(Icons.place_rounded,         'Hajj Season',       'All prayers in Dhul Hijjah 1–10',     isPremium: true),
  _BadgeData(Icons.date_range_rounded,    'Year of Devotion',  '365-day active streak',               isPremium: true),
  _BadgeData(Icons.dark_mode_rounded,     'Silent Worshipper', '30 Fajr prayers before sunrise',      isPremium: true),
  _BadgeData(Icons.military_tech_rounded, 'Legendary',         'Total Streak Score of 1000',          isPremium: true),
];

class _BadgesSection extends StatelessWidget {
  const _BadgesSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Badges',
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1F2D4A), width: 1),
              ),
              child: Text('0 / 13',
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textSubtle,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: _kCoreBadges.length + _kPremiumBadges.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final badge = i < _kCoreBadges.length
                    ? _kCoreBadges[i]
                    : _kPremiumBadges[i - _kCoreBadges.length];
                return _BadgeCell(badge: badge, isEarned: false);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCell extends StatelessWidget {
  final _BadgeData badge;
  final bool isEarned;

  const _BadgeCell({required this.badge, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: 72,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEarned ? AppTheme.primary : const Color(0xFF1F2D4A),
          width: isEarned ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.card,
              border: Border.all(
                color: isEarned ? AppTheme.primary : const Color(0xFF1F2D4A),
                width: isEarned ? 1.5 : 1,
              ),
            ),
            child: Icon(badge.icon, size: 16, color: AppTheme.primary),
          ),
          const SizedBox(height: 7),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );

    if (badge.isPremium) {
      return Stack(
        children: [
          Opacity(opacity: 0.25, child: content),
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 18, color: AppTheme.primary),
                  const SizedBox(height: 3),
                  Text(
                    'Premium',
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (isEarned) return content;

    return Opacity(opacity: 0.25, child: content);
  }
}
