part of '../home_screen.dart';

// ── Greeting ──────────────────────────────────────────────────────────────

class _GreetingRow extends StatelessWidget {
  final String greeting;
  final String displayName;
  const _GreetingRow({required this.greeting, required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assalamu Alaikum',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textSubtle,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$greeting, $displayName',
                style: GoogleFonts.outfit(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ProfileAvatar(size: 46),
      ],
    );
  }
}
