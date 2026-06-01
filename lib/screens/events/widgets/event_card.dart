part of '../events_screen.dart';

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
        border: Border.all(color: AppTheme.card, width: 1),
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
                    colors: [
                      Color(0xFFD4A847),
                      Color(0xFFF0C96A),
                      Color(0xFFD4A847),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: category + badges + distance
                  Row(
                    children: [
                      _CategoryTag(category: event.category),
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (event.isFree) ...[
                            Text(
                              'FREE',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ] else if (event.price != null) ...[
                            Text(
                              '£${event.price!.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          _JoinButton(joined: joined, onTap: onJoin),
                        ],
                      ),
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

// ── Price badge ───────────────────────────────────────────────────────────

class _PriceBadge extends StatelessWidget {
  final double price;
  const _PriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    const col = AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        '£${price.toStringAsFixed(2)}',
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: col,
          letterSpacing: 0.4,
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
                  border: Border.all(color: AppTheme.surface, width: 1.5),
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

  static const _kWidth      = 98.0;
  static const _kIconLeft   = 12.0;
  static const _kIconSize   = 14.0;
  static const _kFontSize   = 13.0;
  static const _kTextOffset = 16.0; // left padding so 'J' in Joined aligns with 'J' in Join
  static const _kGreen      = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final color = joined ? _kGreen : AppTheme.onPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: _kWidth,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: joined ? _kGreen.withValues(alpha: 0.13) : AppTheme.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: joined ? _kGreen.withValues(alpha: 0.45) : AppTheme.primary,
            width: 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: joined ? _kTextOffset : 0),
              child: Text(
                joined ? 'Joined' : 'Join',
                style: GoogleFonts.outfit(
                  fontSize: _kFontSize,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Positioned(
              left: _kIconLeft,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  joined
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: _kIconSize,
                  color: color,
                ),
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
              border: Border.all(color: AppTheme.card, width: 1.5),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
