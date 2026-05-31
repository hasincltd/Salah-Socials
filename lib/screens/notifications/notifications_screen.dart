import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

// ── Global badge state ────────────────────────────────────────────────────

final ValueNotifier<int> unreadNotifCount = ValueNotifier<int>(0);

const _kReadIdsKey      = 'notif_read_ids';
const _kDismissedIdsKey = 'notif_dismissed_ids';
const _kFrStateKey      = 'notif_fr_state_'; // + notif id
const _kSeededKey       = 'notif_seeded';

// Pre-read IDs — these are already read on first launch → 7 will be unread
const _kPreReadIds = ['pr_3', 'st_2', 'st_3', 'cm_2', 'cm_3', 'an_2'];

Future<void> initNotifBadge() async {
  final prefs = await SharedPreferences.getInstance();
  final seeded = prefs.getBool(_kSeededKey) ?? false;
  if (!seeded) {
    await prefs.setStringList(_kReadIdsKey, _kPreReadIds);
    await prefs.setBool(_kSeededKey, true);
  }
  final readIds      = (prefs.getStringList(_kReadIdsKey) ?? []).toSet();
  final dismissedIds = (prefs.getStringList(_kDismissedIdsKey) ?? []).toSet();
  final all          = _buildMockNotifs();
  final unread       = all.where((n) => !dismissedIds.contains(n.id) && !readIds.contains(n.id)).length;
  unreadNotifCount.value = unread;
}

// ── Enums ─────────────────────────────────────────────────────────────────

enum _NSection { friendRequests, prayerAlerts, streakAlerts, communityActivity, appAnnouncements }

extension _NSectionX on _NSection {
  String get title => switch (this) {
    _NSection.friendRequests     => 'Friend Requests',
    _NSection.prayerAlerts       => 'Prayer Alerts',
    _NSection.streakAlerts       => 'Streak Alerts',
    _NSection.communityActivity  => 'Community Activity',
    _NSection.appAnnouncements   => 'App Announcements',
  };

  IconData get icon => switch (this) {
    _NSection.friendRequests     => Icons.people_rounded,
    _NSection.prayerAlerts       => Icons.access_time_rounded,
    _NSection.streakAlerts       => Icons.local_fire_department_rounded,
    _NSection.communityActivity  => Icons.chat_bubble_outline_rounded,
    _NSection.appAnnouncements   => Icons.campaign_outlined,
  };
}

enum _FRState { pending, accepted, declined }

// ── Data model ────────────────────────────────────────────────────────────

class _Notif {
  final String id;
  final _NSection section;
  final String title;
  final String body;
  final String timestamp;
  final bool isFriendRequest;
  final Color? avatarColor;

  const _Notif({
    required this.id,
    required this.section,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isFriendRequest = false,
    this.avatarColor,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────

List<_Notif> _buildMockNotifs() => [
  // Friend Requests
  const _Notif(
    id: 'fr_1', section: _NSection.friendRequests,
    title: 'Abdullah K.', body: 'wants to be your friend',
    timestamp: '2m ago', isFriendRequest: true,
    avatarColor: Color(0xFF4F46E5),
  ),
  const _Notif(
    id: 'fr_2', section: _NSection.friendRequests,
    title: 'Fatima A.', body: 'wants to be your friend',
    timestamp: '1h ago', isFriendRequest: true,
    avatarColor: Color(0xFF059669),
  ),
  // Prayer Alerts
  const _Notif(
    id: 'pr_1', section: _NSection.prayerAlerts,
    title: 'Asr is in 15 minutes',
    body: 'Don\'t miss your afternoon prayer',
    timestamp: '3h ago',
  ),
  const _Notif(
    id: 'pr_2', section: _NSection.prayerAlerts,
    title: 'Maghrib window closing',
    body: 'You have 10 minutes left to log Maghrib',
    timestamp: '5h ago',
  ),
  const _Notif(
    id: 'pr_3', section: _NSection.prayerAlerts,
    title: 'Fajr reminder',
    body: 'Fajr begins in 20 minutes',
    timestamp: 'Yesterday',
  ),
  // Streak Alerts
  const _Notif(
    id: 'st_1', section: _NSection.streakAlerts,
    title: '🔥 7-day streak!',
    body: 'Amazing — you\'ve logged all 5 prayers for 7 days in a row',
    timestamp: '1d ago',
  ),
  const _Notif(
    id: 'st_2', section: _NSection.streakAlerts,
    title: 'Streak at risk',
    body: 'Log your remaining prayers before midnight to keep your streak',
    timestamp: '2d ago',
  ),
  const _Notif(
    id: 'st_3', section: _NSection.streakAlerts,
    title: 'Omar passed you',
    body: 'Omar now has a 14-day streak. Keep going to reclaim your rank!',
    timestamp: '3d ago',
  ),
  // Community Activity
  const _Notif(
    id: 'cm_1', section: _NSection.communityActivity,
    title: 'Yusuf is on a 10-day streak',
    body: 'Your friend Yusuf has been consistent this week — send him a dua',
    timestamp: '4h ago',
  ),
  const _Notif(
    id: 'cm_2', section: _NSection.communityActivity,
    title: 'New mosque member joined',
    body: 'Ahmad from Al-Noor Mosque is now on Salah Socials',
    timestamp: '2d ago',
  ),
  const _Notif(
    id: 'cm_3', section: _NSection.communityActivity,
    title: 'Community milestone',
    body: 'Your mosque community collectively logged 500 prayers this week',
    timestamp: '4d ago',
  ),
  // App Announcements
  const _Notif(
    id: 'an_1', section: _NSection.appAnnouncements,
    title: 'Ramadan Mode coming soon',
    body: 'Special Ramadan tracking features launching next month, in sha Allah',
    timestamp: '1w ago',
  ),
  const _Notif(
    id: 'an_2', section: _NSection.appAnnouncements,
    title: 'Version 1.2 released',
    body: 'Bug fixes and performance improvements. Jazakallah khair for your feedback',
    timestamp: '2w ago',
  ),
];

// ── Bell icon button (used across all screens) ────────────────────────────

class BellIconButton extends StatelessWidget {
  const BellIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: unreadNotifCount,
      builder: (context, count, _) {
        return IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                count > 0 ? Icons.notifications_rounded : Icons.notifications_outlined,
                size: 22,
                color: AppTheme.textSubtle,
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
        );
      },
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notif> _notifs = _buildMockNotifs();
  Set<String> _readIds = {};
  Set<String> _dismissedIds = {};
  Map<String, _FRState> _frStates = {};

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final readIds      = (prefs.getStringList(_kReadIdsKey) ?? []).toSet();
    final dismissedIds = (prefs.getStringList(_kDismissedIdsKey) ?? []).toSet();
    final frStates = <String, _FRState>{};
    for (final n in _notifs) {
      if (n.isFriendRequest) {
        final raw = prefs.getString('$_kFrStateKey${n.id}');
        frStates[n.id] = switch (raw) {
          'accepted' => _FRState.accepted,
          'declined' => _FRState.declined,
          _ => _FRState.pending,
        };
      }
    }
    setState(() {
      _readIds      = readIds;
      _dismissedIds = dismissedIds;
      _notifs.removeWhere((n) => dismissedIds.contains(n.id));
      _frStates = frStates;
    });
  }

  Future<void> _markRead(String id) async {
    if (_readIds.contains(id)) return;
    final prefs = await SharedPreferences.getInstance();
    final updated = {..._readIds, id};
    await prefs.setStringList(_kReadIdsKey, updated.toList());
    setState(() => _readIds = updated);
    unreadNotifCount.value = _notifs.where((n) => !updated.contains(n.id)).length;
  }

  Future<void> _markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final all = _notifs.map((n) => n.id).toSet();
    await prefs.setStringList(_kReadIdsKey, all.toList());
    setState(() => _readIds = all);
    unreadNotifCount.value = 0;
  }

  Future<void> _setFRState(String id, _FRState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kFrStateKey$id', state.name);
    setState(() => _frStates[id] = state);
    await _markRead(id);
  }

  Future<void> _dismiss(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = {..._dismissedIds, id};
    await prefs.setStringList(_kDismissedIdsKey, updated.toList());
    setState(() {
      _dismissedIds = updated;
      _notifs.removeWhere((n) => n.id == id);
    });
    unreadNotifCount.value = _notifs.where((n) => !_readIds.contains(n.id)).length;
  }

  int get _unreadCount => _notifs.where((n) => !_readIds.contains(n.id)).length;

  @override
  Widget build(BuildContext context) {
    final sections = _NSection.values;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: sections.length,
        itemBuilder: (context, si) {
          final section = sections[si];
          final items = _notifs.where((n) => n.section == section).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(section: section),
              ...items.map((n) {
                final isRead = _readIds.contains(n.id);
                if (n.isFriendRequest) {
                  return _FriendRequestRow(
                    notif: n,
                    isRead: isRead,
                    frState: _frStates[n.id] ?? _FRState.pending,
                    onAccept: () => _setFRState(n.id, _FRState.accepted),
                    onDecline: () => _setFRState(n.id, _FRState.declined),
                    onTap: () => _markRead(n.id),
                  );
                }
                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _dismiss(n.id),
                  background: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                  ),
                  child: _NotifRow(
                    notif: n,
                    isRead: isRead,
                    onTap: () => _markRead(n.id),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

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
                        fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
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
                  _Avatar(name: notif.title, color: notif.avatarColor ?? AppTheme.surface),
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
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
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
                            color: AppTheme.textSubtle.withValues(alpha: 0.7),
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
                      onTap: onAccept,
                    ),
                    const SizedBox(width: 8),
                    _FRButton(
                      label: 'Decline',
                      color: AppTheme.error,
                      onTap: onDecline,
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (frState == _FRState.accepted ? AppTheme.accent : AppTheme.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    frState == _FRState.accepted ? 'Request accepted' : 'Request declined',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: frState == _FRState.accepted ? AppTheme.accent : AppTheme.error,
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

  const _FRButton({required this.label, required this.color, required this.onTap});

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
    final initials = name.trim().split(' ').take(2).map((s) => s.isEmpty ? '' : s[0]).join();
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
