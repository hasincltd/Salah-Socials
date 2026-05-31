import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class S6Notifications extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const S6Notifications(
      {super.key, required this.onAllow, required this.onSkip});

  static const List<_NotifPreview> _previews = [
    _NotifPreview(
        Icons.wb_twilight_rounded,
        'Prayer Alerts',
        'Get reminded before Fajr, Dhuhr, Asr, Maghrib and Isha',
        AppTheme.primary),
    _NotifPreview(
        Icons.local_fire_department_rounded,
        'Streak Alerts',
        "Don't lose your streak — we'll nudge you if a prayer is missed",
        Color(0xFFFF8C42)),
    _NotifPreview(
        Icons.people_rounded,
        'Friend Activity',
        'See when friends complete prayers and hit milestones',
        Color(0xFF2DD4A0)),
    _NotifPreview(
        Icons.mosque_rounded,
        'Mosque Updates',
        'Prayer time changes and announcements from your mosque',
        Color(0xFF9B59F5)),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Stay on Track',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Get notified so you never miss a prayer',
              style:
                  GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSubtle),
            ),
            const SizedBox(height: 24),
            // Notification previews
            Expanded(
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _previews.length,
                separatorBuilder: (context, i) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _NotifCard(preview: _previews[i]),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAllow,
                icon: const Icon(Icons.notifications_active_rounded, size: 18),
                label: const Text('Allow Notifications'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: onSkip,
                child: Text(
                  'Not now  ·  Enable in Settings anytime',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppTheme.textSubtle),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _NotifPreview {
  final IconData icon;
  final String title;
  final String body;
  final Color color;

  const _NotifPreview(this.icon, this.title, this.body, this.color);
}

class _NotifCard extends StatelessWidget {
  final _NotifPreview preview;

  const _NotifCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2D4A), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: preview.color.withValues(alpha: 0.12),
            ),
            child: Icon(preview.icon, size: 20, color: preview.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(preview.title,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 3),
                Text(preview.body,
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textSubtle,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
