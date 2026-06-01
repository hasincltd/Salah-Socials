part of '../notifications_screen.dart';

// ── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final _NSection section;
  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Row(
        children: [
          Icon(section.icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            section.title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Standard notification row ─────────────────────────────────────────────

class _NotifRow extends StatelessWidget {
  final _Notif notif;
  final bool isRead;
  final VoidCallback onTap;

  const _NotifRow({
    required this.notif,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: isRead
                ? BorderSide.none
                : const BorderSide(color: AppTheme.primary, width: 3),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isRead ? 14 : 11, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notif.section.icon,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight:
                            isRead ? FontWeight.w400 : FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.body,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textSubtle,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.timestamp,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.textSubtle.withValues(alpha: 0.7),
                      ),
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

// ── Friend request row ────────────────────────────────────────────────────

class _FriendRequestRow extends StatelessWidget {
  final _Notif notif;
  final bool isRead;
  final _FRState frState;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTap;

  const _FriendRequestRow({
    required this.notif,
    required this.isRead,
    required this.frState,
    required this.onAccept,
    required this.onDecline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: isRead
                ? BorderSide.none
                : const BorderSide(color: AppTheme.primary, width: 3),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(isRead ? 14 : 11, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(
                      name: notif.title,
                      color: notif.avatarColor ?? AppTheme.surface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: notif.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: ' ${notif.body}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.textSubtle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notif.timestamp,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color:
                                AppTheme.textSubtle.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (frState == _FRState.pending) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    _FRButton(
                        label: 'Accept',
                        color: AppTheme.accent,
                        onTap: onAccept),
                    const SizedBox(width: 8),
                    _FRButton(
                        label: 'Decline',
                        color: AppTheme.error,
                        onTap: onDecline),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (frState == _FRState.accepted
                            ? AppTheme.accent
                            : AppTheme.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    frState == _FRState.accepted
                        ? 'Request accepted'
                        : 'Request declined',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: frState == _FRState.accepted
                          ? AppTheme.accent
                          : AppTheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── FR action button ──────────────────────────────────────────────────────

class _FRButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FRButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final Color color;

  const _Avatar({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((s) => s.isEmpty ? '' : s[0])
        .join();
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
