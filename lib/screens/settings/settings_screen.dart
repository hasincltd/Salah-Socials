import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

part 'widgets/settings_widgets.dart';

// ── Preference keys ───────────────────────────────────────────────────────

const _kUsername         = 'settings_username';
const _kDisplayName      = 'settings_display_name';
const _kHomeLocation     = 'settings_home_location';
const _kCalcMethod       = 'settings_calc_method';
const _kMadhab           = 'settings_madhab';
const _kNotifyFajr       = 'settings_notify_fajr';
const _kNotifyDhuhr      = 'settings_notify_dhuhr';
const _kNotifyAsr        = 'settings_notify_asr';
const _kNotifyMaghrib    = 'settings_notify_maghrib';
const _kNotifyIsha       = 'settings_notify_isha';
const _kNotifyTiming     = 'settings_notify_timing';
const _kWarn15           = 'settings_warn_15';
const _kCommunityNotif   = 'settings_community_notif';
const _kStreakNotif       = 'settings_streak_notif';
const _kTravelerAlerts   = 'settings_traveler_alerts';
const _kDndEnabled       = 'settings_dnd_enabled';
const _kDndStartHour     = 'settings_dnd_start_hour';
const _kDndStartMinute   = 'settings_dnd_start_minute';
const _kDndEndHour       = 'settings_dnd_end_hour';
const _kDndEndMinute     = 'settings_dnd_end_minute';
const _kFriendRequests   = 'settings_friend_requests';
const _kProfileVisible   = 'settings_profile_visibility';
const _kLeaderboardOut   = 'settings_leaderboard_opt_out';

// ── Option lists ──────────────────────────────────────────────────────────

const _calcMethods = [
  'Muslim World League',
  'Egyptian General Authority',
  'Univ. of Islamic Sciences, Karachi',
  'ISNA (North America)',
  'Moon Sighting Committee',
];

const _timingOptions = [
  'At prayer time',
  '15 min before',
  '30 min before',
];

// ── Screen ────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Account
  String _username    = 'Hasin';
  String _displayName = 'Hasin';

  // Location
  String _homeLocation = '';

  // Prayer Settings
  String _calcMethod = 'Muslim World League';
  String _madhab     = 'Hanafi';

  // Notifications — per-prayer toggles
  bool _notifyFajr    = true;
  bool _notifyDhuhr   = true;
  bool _notifyAsr     = true;
  bool _notifyMaghrib = true;
  bool _notifyIsha    = true;
  // Notifications — global settings
  String _notifyTiming  = 'At prayer time';
  bool _warn15          = false;
  bool _communityNotif  = true;
  bool _streakNotif     = true;
  bool _travelerAlerts  = true;
  bool _dndEnabled      = false;
  TimeOfDay _dndStart   = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _dndEnd     = const TimeOfDay(hour: 6,  minute: 0);

  // Privacy
  String _friendRequests    = 'Everyone';
  String _profileVisibility = 'Public';
  bool _leaderboardOptOut   = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _username         = p.getString(_kUsername)       ?? 'Hasin';
      _displayName      = p.getString(_kDisplayName)    ?? 'Hasin';
      _homeLocation     = p.getString(_kHomeLocation)   ?? '';
      _calcMethod       = p.getString(_kCalcMethod)     ?? 'Muslim World League';
      _madhab           = p.getString(_kMadhab)         ?? 'Hanafi';
      _notifyFajr       = p.getBool(_kNotifyFajr)       ?? true;
      _notifyDhuhr      = p.getBool(_kNotifyDhuhr)      ?? true;
      _notifyAsr        = p.getBool(_kNotifyAsr)        ?? true;
      _notifyMaghrib    = p.getBool(_kNotifyMaghrib)    ?? true;
      _notifyIsha       = p.getBool(_kNotifyIsha)       ?? true;
      _notifyTiming     = p.getString(_kNotifyTiming)   ?? 'At prayer time';
      _warn15           = p.getBool(_kWarn15)           ?? false;
      _communityNotif   = p.getBool(_kCommunityNotif)   ?? true;
      _streakNotif      = p.getBool(_kStreakNotif)       ?? true;
      _travelerAlerts   = p.getBool(_kTravelerAlerts)   ?? true;
      _dndEnabled       = p.getBool(_kDndEnabled)       ?? false;
      _dndStart         = TimeOfDay(
        hour:   p.getInt(_kDndStartHour)   ?? 22,
        minute: p.getInt(_kDndStartMinute) ?? 0,
      );
      _dndEnd           = TimeOfDay(
        hour:   p.getInt(_kDndEndHour)   ?? 6,
        minute: p.getInt(_kDndEndMinute) ?? 0,
      );
      _friendRequests    = p.getString(_kFriendRequests) ?? 'Everyone';
      _profileVisibility = p.getString(_kProfileVisible) ?? 'Public';
      _leaderboardOptOut = p.getBool(_kLeaderboardOut)   ?? false;
    });
  }

  // Fire-and-forget single-value pref save.
  Future<void> _sp(Future<bool> Function(SharedPreferences) fn) async =>
      fn(await SharedPreferences.getInstance());

  // ── Dialogs and pickers ───────────────────────────────────────────────

  Future<void> _editDialog({
    required String title,
    required String initial,
    required ValueChanged<String> onSave,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: GoogleFonts.outfit(
            fontSize: 17, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.outfit(fontSize: 15, color: AppTheme.textPrimary),
          cursorColor: AppTheme.primary,
          decoration: InputDecoration(
            hintText: 'Enter $title',
            hintStyle: GoogleFonts.outfit(color: AppTheme.textSubtle),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(
                color: AppTheme.textSubtle, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Save', style: GoogleFonts.outfit(
                color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) onSave(result);
  }

  Future<void> _pickerSheet({
    required String title,
    required List<String> options,
    required String current,
    required ValueChanged<String> onPicked,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.textSubtle.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
              ),
            ),
            ...options.map((opt) {
              final sel = opt == current;
              return InkWell(
                onTap: () { onPicked(opt); Navigator.pop(ctx); },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                  decoration: const BoxDecoration(
                      border: Border(top: BorderSide(
                          color: Color(0xFF192036), width: 0.5))),
                  child: Row(children: [
                    Expanded(child: Text(opt, style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? AppTheme.primary : AppTheme.textPrimary))),
                    if (sel)
                      const Icon(Icons.check_rounded,
                          color: AppTheme.primary, size: 18),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccountDialog() async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Delete Account', style: GoogleFonts.outfit(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: AppTheme.error)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This is permanent and cannot be undone. '
                'All streak history, SS Coins, and data will be lost.',
                style: GoogleFonts.outfit(
                    fontSize: 13, color: AppTheme.textSubtle, height: 1.5)),
              const SizedBox(height: 16),
              Text('Type DELETE to confirm:',
                  style: GoogleFonts.outfit(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: GoogleFonts.outfit(
                    fontSize: 14, color: AppTheme.textPrimary),
                cursorColor: AppTheme.error,
                onChanged: (_) => setLocal(() {}),
                decoration: InputDecoration(
                  hintText: 'DELETE',
                  hintStyle: GoogleFonts.outfit(color: AppTheme.textSubtle),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.outfit(
                  color: AppTheme.textSubtle, fontWeight: FontWeight.w500)),
            ),
            TextButton(
              onPressed: ctrl.text == 'DELETE'
                  ? () {
                      Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Account deleted.',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textPrimary)),
                          backgroundColor: AppTheme.surface,
                        ));
                      }
                    }
                  : null,
              child: Text('Delete',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      color: ctrl.text == 'DELETE'
                          ? AppTheme.error
                          : AppTheme.textSubtle.withValues(alpha: 0.4))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upgradeDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('Upgrade to Premium', style: GoogleFonts.outfit(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: AppTheme.primary)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unlock unlimited streak revives, 30-day history, '
              'premium badges, and more.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppTheme.textSubtle, height: 1.5)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.25)),
              ),
              child: Column(children: [
                Text('Premium', style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
                const SizedBox(height: 4),
                Text('Subscription payments coming soon',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.textSubtle)),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.outfit(
                color: AppTheme.textSubtle, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Notify Me', style: GoogleFonts.outfit(
                color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _locationDialog() async {
    final ctrl = TextEditingController(text: _homeLocation);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Home Location', style: GoogleFonts.outfit(
            fontSize: 17, fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: GoogleFonts.outfit(
                  fontSize: 15, color: AppTheme.textPrimary),
              cursorColor: AppTheme.primary,
              decoration: InputDecoration(
                hintText: 'e.g. E1 1AA',
                hintStyle: GoogleFonts.outfit(color: AppTheme.textSubtle),
                prefixIcon: const Icon(Icons.location_on_rounded,
                    color: AppTheme.primary, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            Text('Pin-drop map coming in a future update.',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppTheme.textSubtle)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(
                color: AppTheme.textSubtle, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Save', style: GoogleFonts.outfit(
                color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _homeLocation = result);
      _sp((p) => p.setString(_kHomeLocation, result));
    }
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppTheme.primary,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
      backgroundColor: AppTheme.surface,
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          color: AppTheme.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings',
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.card),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          // ── ACCOUNT ────────────────────────────────────────────────
          const _SectionHeader('ACCOUNT'),
          _SettingsCard([
            _SettingsNavRow(
              title: 'Username',
              subtitle: _username,
              onTap: () => _editDialog(
                title: 'Username',
                initial: _username,
                onSave: (v) {
                  setState(() => _username = v);
                  _sp((p) => p.setString(_kUsername, v));
                },
              ),
            ),
            _SettingsNavRow(
              title: 'Display Name',
              subtitle: _displayName,
              onTap: () => _editDialog(
                title: 'Display Name',
                initial: _displayName,
                onSave: (v) {
                  setState(() => _displayName = v);
                  _sp((p) => p.setString(_kDisplayName, v));
                },
              ),
            ),
            _SettingsNavRow(
              title: 'Profile Picture',
              subtitle: 'Change avatar',
              onTap: () => _snack('Profile picture upload coming soon'),
            ),
            _SettingsNavRow(
              title: 'Change Password',
              onTap: () => _snack('Password change coming soon'),
            ),
            _SettingsNavRow(
              title: 'Delete Account',
              titleColor: AppTheme.error,
              isLast: true,
              onTap: _deleteAccountDialog,
            ),
          ]),

          // ── LOCATION ───────────────────────────────────────────────
          const _SectionHeader('LOCATION'),
          _SettingsCard([
            _SettingsNavRow(
              title: 'Home Location',
              subtitle: _homeLocation.isEmpty ? 'Not set' : _homeLocation,
              onTap: _locationDialog,
            ),
            _SettingsNavRow(
              title: 'Reset to Current GPS',
              isLast: true,
              onTap: () => _snack('GPS reset coming soon'),
            ),
          ]),

          // ── PRAYER SETTINGS ────────────────────────────────────────
          const _SectionHeader('PRAYER SETTINGS'),
          _SettingsCard([
            _SettingsNavRow(
              title: 'Calculation Method',
              subtitle: _calcMethod,
              onTap: () => _pickerSheet(
                title: 'Calculation Method',
                options: _calcMethods,
                current: _calcMethod,
                onPicked: (v) {
                  setState(() => _calcMethod = v);
                  _sp((p) => p.setString(_kCalcMethod, v));
                },
              ),
            ),
            _SettingsNavRow(
              title: 'Madhab for Asr',
              subtitle: _madhab,
              isLast: true,
              onTap: () => _pickerSheet(
                title: 'Madhab for Asr',
                options: const ['Hanafi', "Shafi'i"],
                current: _madhab,
                onPicked: (v) {
                  setState(() => _madhab = v);
                  _sp((p) => p.setString(_kMadhab, v));
                },
              ),
            ),
          ]),

          // ── NOTIFICATIONS ──────────────────────────────────────────
          const _SectionHeader('NOTIFICATIONS'),
          _SettingsCard([
            _SettingsToggleRow(
              title: 'Fajr',
              value: _notifyFajr,
              onChanged: (v) {
                setState(() => _notifyFajr = v);
                _sp((p) => p.setBool(_kNotifyFajr, v));
              },
            ),
            _SettingsToggleRow(
              title: 'Dhuhr',
              value: _notifyDhuhr,
              onChanged: (v) {
                setState(() => _notifyDhuhr = v);
                _sp((p) => p.setBool(_kNotifyDhuhr, v));
              },
            ),
            _SettingsToggleRow(
              title: 'Asr',
              value: _notifyAsr,
              onChanged: (v) {
                setState(() => _notifyAsr = v);
                _sp((p) => p.setBool(_kNotifyAsr, v));
              },
            ),
            _SettingsToggleRow(
              title: 'Maghrib',
              value: _notifyMaghrib,
              onChanged: (v) {
                setState(() => _notifyMaghrib = v);
                _sp((p) => p.setBool(_kNotifyMaghrib, v));
              },
            ),
            _SettingsToggleRow(
              title: 'Isha',
              value: _notifyIsha,
              onChanged: (v) {
                setState(() => _notifyIsha = v);
                _sp((p) => p.setBool(_kNotifyIsha, v));
              },
            ),
            _SettingsNavRow(
              title: 'Notification Timing',
              subtitle: _notifyTiming,
              onTap: () => _pickerSheet(
                title: 'Notification Timing',
                options: _timingOptions,
                current: _notifyTiming,
                onPicked: (v) {
                  setState(() => _notifyTiming = v);
                  _sp((p) => p.setString(_kNotifyTiming, v));
                },
              ),
            ),
            _SettingsToggleRow(
              title: '15-Minute Warning',
              subtitle: 'Extra alert 15 min before each prayer',
              value: _warn15,
              onChanged: (v) {
                setState(() => _warn15 = v);
                _sp((p) => p.setBool(_kWarn15, v));
              },
            ),
            _SettingsToggleRow(
              title: 'Community Notifications',
              subtitle: 'Friend activity, events, and mentions',
              value: _communityNotif,
              onChanged: (v) {
                setState(() => _communityNotif = v);
                _sp((p) => p.setBool(_kCommunityNotif, v));
              },
            ),
            _SettingsToggleRow(
              title: 'Streak Notifications',
              subtitle: 'Reminders to protect your streak',
              value: _streakNotif,
              onChanged: (v) {
                setState(() => _streakNotif = v);
                _sp((p) => p.setBool(_kStreakNotif, v));
              },
            ),
            _SettingsToggleRow(
              title: 'Traveler Alerts',
              subtitle: 'Nearest mosque alert when away from home near prayer time',
              value: _travelerAlerts,
              onChanged: (v) {
                setState(() => _travelerAlerts = v);
                _sp((p) => p.setBool(_kTravelerAlerts, v));
              },
            ),
            _SettingsToggleRow(
              title: 'Do Not Disturb',
              subtitle: 'Fajr overrides DND with gentle sound only',
              value: _dndEnabled,
              onChanged: (v) {
                setState(() => _dndEnabled = v);
                _sp((p) => p.setBool(_kDndEnabled, v));
              },
            ),
            _SettingsNavRow(
              title: 'DND Start',
              subtitle: _dndStart.format(context),
              onTap: () => _pickTime(
                initial: _dndStart,
                onPicked: (t) async {
                  setState(() => _dndStart = t);
                  final p = await SharedPreferences.getInstance();
                  await p.setInt(_kDndStartHour, t.hour);
                  await p.setInt(_kDndStartMinute, t.minute);
                },
              ),
            ),
            _SettingsNavRow(
              title: 'DND End',
              subtitle: _dndEnd.format(context),
              isLast: true,
              onTap: () => _pickTime(
                initial: _dndEnd,
                onPicked: (t) async {
                  setState(() => _dndEnd = t);
                  final p = await SharedPreferences.getInstance();
                  await p.setInt(_kDndEndHour, t.hour);
                  await p.setInt(_kDndEndMinute, t.minute);
                },
              ),
            ),
          ]),

          // ── SUBSCRIPTION ───────────────────────────────────────────
          const _SectionHeader('SUBSCRIPTION'),
          _SettingsCard([
            _SettingsInfoRow(title: 'Current Plan', value: 'Core'),
            _SettingsNavRow(
              title: 'Upgrade to Premium',
              titleColor: AppTheme.primary,
              isLast: true,
              onTap: _upgradeDialog,
            ),
          ]),

          // ── PRIVACY ────────────────────────────────────────────────
          const _SectionHeader('PRIVACY'),
          _SettingsCard([
            _SettingsNavRow(
              title: 'Friend Requests',
              subtitle: _friendRequests,
              onTap: () => _pickerSheet(
                title: 'Who Can Send Friend Requests',
                options: const ['Everyone', 'Nobody'],
                current: _friendRequests,
                onPicked: (v) {
                  setState(() => _friendRequests = v);
                  _sp((p) => p.setString(_kFriendRequests, v));
                },
              ),
            ),
            _SettingsNavRow(
              title: 'Profile Visibility',
              subtitle: _profileVisibility,
              onTap: () => _pickerSheet(
                title: 'Profile Visibility',
                options: const ['Public', 'Friends Only'],
                current: _profileVisibility,
                onPicked: (v) {
                  setState(() => _profileVisibility = v);
                  _sp((p) => p.setString(_kProfileVisible, v));
                },
              ),
            ),
            _SettingsToggleRow(
              title: 'Leaderboard Opt-Out',
              subtitle: 'Hide your name from all leaderboards',
              value: _leaderboardOptOut,
              isLast: true,
              onChanged: (v) {
                setState(() => _leaderboardOptOut = v);
                _sp((p) => p.setBool(_kLeaderboardOut, v));
              },
            ),
          ]),

          // ── APP ────────────────────────────────────────────────────
          const _SectionHeader('APP'),
          _SettingsCard([
            _SettingsInfoRow(title: 'App Version', value: '1.0.0 (1)'),
            _SettingsNavRow(
              title: 'Terms of Service',
              onTap: () => _snack('Terms of Service coming soon'),
            ),
            _SettingsNavRow(
              title: 'Privacy Policy',
              onTap: () => _snack('Privacy Policy coming soon'),
            ),
            _SettingsNavRow(
              title: 'Contact Support',
              isLast: true,
              onTap: () async {
                final uri = Uri.parse('mailto:support@salahsocials.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else if (mounted) {
                  _snack('Contact support@salahsocials.com');
                }
              },
            ),
          ]),
        ],
      ),
    );
  }
}
