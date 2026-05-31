part of '../home_screen.dart';

// ── Greeting ──────────────────────────────────────────────────────────────

class _GreetingRow extends StatelessWidget {
  final String greeting;
  const _GreetingRow({required this.greeting});

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
                '$greeting, Hasin',
                style: GoogleFonts.outfit(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary,
            border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.4), width: 2),
          ),
          child: Center(
            child: Text('H',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onPrimary,
                )),
          ),
        ),
      ],
    );
  }
}
