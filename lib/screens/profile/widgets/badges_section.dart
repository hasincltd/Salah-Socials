part of '../profile_screen.dart';

// ── Badges section ────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  const _BadgesSection();

  static const List<(IconData, String)> _badges = [
    (Icons.mosque_rounded,                'First Prayer'),
    (Icons.home_rounded,                  'Full House'),
    (Icons.local_fire_department_rounded, 'Week One'),
    (Icons.wb_twilight_rounded,           'Fajr Warrior'),
    (Icons.nightlight_round,              'Night Owl'),
  ];

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF1F2D4A), width: 1),
              ),
              child: Text('0 / 13',
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppTheme.textSubtle,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                _badges.map((b) => _BadgeItem(icon: b.$1, name: b.$2)).toList(),
          ),
        ],
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String name;
  const _BadgeItem({required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25,
      child: SizedBox(
        width: 58,
        child: Column(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              border:
                  Border.all(color: const Color(0xFF1F2D4A), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppTheme.primary),
          ),
          const SizedBox(height: 5),
          Text(name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSubtle)),
        ]),
      ),
    );
  }
}
