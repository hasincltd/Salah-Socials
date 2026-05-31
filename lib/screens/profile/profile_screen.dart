import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/ss_coins_widget.dart';

part 'widgets/profile_banner.dart';
part 'widgets/profile_stats_row.dart';
part 'widgets/my_avatar_tab.dart';
part 'widgets/salah_seasons_tab.dart';
part 'widgets/badges_section.dart';

// ── SharedPreferences keys ────────────────────────────────────────────────

const _kDisplayName    = 'settings_display_name';
const _kUsername       = 'settings_username';
const _kSsCoins        = 'ss_coin_balance';
const _kSsCoinsDefault = 1000;
const _prayerNames     = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

// ── Screen ────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = 'Hasin';
  String _username    = 'hasin';
  int    _streakDays  = 0;
  int    _ssCoins     = _kSsCoinsDefault;
  static const int _friendsCount = 6;

  late final PageController _pageController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadStats();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayName = prefs.getString(_kDisplayName) ?? 'Hasin';
      _username    = prefs.getString(_kUsername) ?? 'hasin';
      _ssCoins     = prefs.getInt(_kSsCoins) ?? _kSsCoinsDefault;
      _streakDays  = _computeStreak(prefs);
    });
  }

  int _computeStreak(SharedPreferences prefs) {
    String key(String dk, String n) => 'prayer_log_${dk}_$n';
    String fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
    var day = DateTime.now();
    if (!_prayerNames.every((n) => prefs.getBool(key(fmt(day), n)) == true)) {
      day = day.subtract(const Duration(days: 1));
    }
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final dk = fmt(day);
      if (_prayerNames.every((n) => prefs.getBool(key(dk, n)) == true)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  void _switchTab(int i) {
    setState(() => _tabIndex = i);
    _pageController.animateToPage(i,
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void _showMessageSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Messaging coming soon',
          style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
      backgroundColor: AppTheme.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final topPad     = MediaQuery.of(context).padding.top;
    const bannerVisH = 140.0;
    const avatarR    = 44.0;
    const overlap    = 32.0;
    final headerH    = topPad + bannerVisH + avatarR * 2 - overlap;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Banner + icons + avatar circle + stats ────────────────
            SizedBox(
              height: headerH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: SizedBox(
                      height: topPad + bannerVisH,
                      child: CustomPaint(painter: _BannerPainter()),
                    ),
                  ),
                  Positioned(
                    top: topPad + 6, left: 4,
                    child: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                      color: AppTheme.textSubtle.withValues(alpha: 0.55),
                      onPressed: _showMessageSnack,
                    ),
                  ),
                  Positioned(
                    top: topPad + 2, right: 0,
                    child: Row(children: [
                      const BellIconButton(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, size: 20),
                        color: AppTheme.textSubtle,
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen())),
                      ),
                    ]),
                  ),
                  Positioned(
                    bottom: 0, left: 16,
                    child: Container(
                      width: avatarR * 2,
                      height: avatarR * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.background, width: 3),
                      ),
                      child: ClipOval(
                        child: CustomPaint(
                          painter: _ProfileAvatarPainter(),
                          size: Size(avatarR * 2, avatarR * 2),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 16 + avatarR * 2 + 14,
                    right: 16,
                    child: _StatsRow(
                      streakDays: _streakDays,
                      ssCoins: _ssCoins,
                      friendsCount: _friendsCount,
                    ),
                  ),
                ],
              ),
            ),
            // ── 2. Name + handle + bio ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName,
                      style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text('@$_username',
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  Text('Living with intention, one prayer at a time.',
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: AppTheme.textSubtle)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            // ── 3. Tab pills ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _TabPills(tabIndex: _tabIndex, onSwitch: _switchTab),
            ),
            const SizedBox(height: 12),
            // ── SS Coins — persistent above tab content ──────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SSCoinWidget(),
            ),
            const SizedBox(height: 10),
            // ── 4. PageView ──────────────────────────────────────────────
            SizedBox(
              height: 490,
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _tabIndex = i),
                children: const [
                  _MyAvatarTab(),
                  _SalahSeasonsTab(),
                ],
              ),
            ),
            // ── 5. Badges ────────────────────────────────────────────────
            const _BadgesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Tab pills ─────────────────────────────────────────────────────────────

class _TabPills extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onSwitch;
  const _TabPills({required this.tabIndex, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _Pill(
                label: 'My Avatar',
                selected: tabIndex == 0,
                onTap: () => onSwitch(0))),
        const SizedBox(width: 10),
        Expanded(
            child: _Pill(
                label: 'Salah Seasons',
                selected: tabIndex == 1,
                onTap: () => onSwitch(1))),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.10)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFF1F2D4A),
            width: 1,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.primary : AppTheme.textSubtle)),
      ),
    );
  }
}
