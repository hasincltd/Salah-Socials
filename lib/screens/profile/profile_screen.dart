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

// ── Banner painter — vibrant Islamic geometric ────────────────────────────

class _BannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Rich gradient background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1B3E),
            Color(0xFF08242A),
            Color(0xFF1A1040),
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Grid of 8-pointed Islamic stars — gold fill
    final starFill = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.11)
      ..style = PaintingStyle.fill;
    final starStroke = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    const r = 20.0;
    const sp = 52.0;
    for (double x = sp / 2; x < size.width + sp; x += sp) {
      for (double y = sp / 2; y < size.height + sp; y += sp) {
        _star8(canvas, Offset(x, y), r, starFill);
        _star8(canvas, Offset(x, y), r, starStroke);
      }
    }

    // Offset row — teal accent stars (smaller)
    final tealFill = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    for (double x = sp; x < size.width + sp; x += sp) {
      for (double y = sp; y < size.height + sp; y += sp) {
        _star8(canvas, Offset(x, y), r * 0.45, tealFill);
      }
    }

    // Interlocking circle lattice
    final circlePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (double x = 0; x <= size.width + 36; x += 36) {
      for (double y = 0; y <= size.height + 36; y += 36) {
        canvas.drawCircle(Offset(x, y), 18, circlePaint);
      }
    }

    // Radial gold glow centre-right
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.6, -0.3),
          radius: 0.9,
          colors: [
            AppTheme.primary.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Teal glow left side
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, 0.4),
          radius: 0.7,
          colors: [
            AppTheme.accent.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Bottom fade to background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, AppTheme.background.withValues(alpha: 0.60)],
          stops: const [0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _star8(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    final inner = r * 0.42;
    for (int i = 0; i < 8; i++) {
      final oa = (i * math.pi / 4) - math.pi / 2;
      final ia = oa + math.pi / 8;
      final ox = c.dx + r * math.cos(oa);
      final oy = c.dy + r * math.sin(oa);
      final ix = c.dx + inner * math.cos(ia);
      final iy = c.dy + inner * math.sin(ia);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BannerPainter old) => false;
}

// ── Profile avatar painter — circular head + shoulders ────────────────────

class _ProfileAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Teal-dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0E2A28),
    );

    final skin = Paint()..color = const Color(0xFFE8B89A);
    final hair = Paint()..color = const Color(0xFF3D2314);
    final top  = Paint()..color = AppTheme.accent;

    // Shoulders
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - 30, cy + 6, cx + 30, size.height + 8),
        const Radius.circular(14),
      ),
      top,
    );

    // Neck
    canvas.drawRect(
      Rect.fromLTRB(cx - 7, cy - 2, cx + 7, cy + 10),
      skin,
    );

    // Head
    final hR = size.width * 0.26;
    canvas.drawCircle(Offset(cx, cy - hR * 0.3), hR, skin);

    // Hair cap (top semicircle)
    final hairPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, cy - hR * 0.3), radius: hR * 1.01),
        math.pi, math.pi,
      )
      ..close();
    canvas.drawPath(hairPath, hair);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF2A1A0A);
    canvas.drawCircle(Offset(cx - 6, cy - hR * 0.25), 2.0, eyePaint);
    canvas.drawCircle(Offset(cx + 6, cy - hR * 0.25), 2.0, eyePaint);

    // Smile
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, cy - hR * 0.05), width: 11, height: 7),
      0, math.pi, false,
      Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProfileAvatarPainter old) => false;
}

// ── Full-body avatar character painter ───────────────────────────────────

class _FullBodyAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final skin  = Paint()..color = const Color(0xFFE8B89A);
    final hair  = Paint()..color = const Color(0xFF3D2314);
    final shirt = Paint()..color = AppTheme.accent;
    final pants = Paint()..color = const Color(0xFF1A2440);
    final shoes = Paint()..color = AppTheme.primary;
    final eye   = Paint()..color = const Color(0xFF2A1A0A);
    final belt  = Paint()..color = AppTheme.primary;

    final headCY  = size.height * 0.13;
    final headR   = size.width  * 0.16;
    final neckTop = headCY + headR - 2;
    final neckBot = neckTop + size.height * 0.05;
    final bodyTop = neckBot;
    final bodyBot = size.height * 0.60;
    final legsBot = size.height * 0.88;
    final shoesBot = size.height * 0.97;
    final legW    = size.width * 0.16;
    final armW    = size.width * 0.095;

    // ── Legs ─────────────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - legW * 1.25, bodyBot - 4, cx - 2, legsBot),
        const Radius.circular(6)),
      pants,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + 2, bodyBot - 4, cx + legW * 1.25, legsBot),
        const Radius.circular(6)),
      pants,
    );

    // ── Shoes ─────────────────────────────────────────────────────────────
    canvas.drawOval(
        Rect.fromLTRB(cx - legW * 1.6, legsBot - 6, cx + 4, shoesBot), shoes);
    canvas.drawOval(
        Rect.fromLTRB(cx - 4, legsBot - 6, cx + legW * 1.6, shoesBot), shoes);

    // ── Arms ──────────────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - size.width * 0.37, bodyTop + 4,
            cx - size.width * 0.26, bodyBot - 12),
        const Radius.circular(8)),
      shirt,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + size.width * 0.26, bodyTop + 4,
            cx + size.width * 0.37, bodyBot - 12),
        const Radius.circular(8)),
      shirt,
    );
    // Hands
    canvas.drawCircle(
        Offset(cx - size.width * 0.315, bodyBot - 9), armW * 0.72, skin);
    canvas.drawCircle(
        Offset(cx + size.width * 0.315, bodyBot - 9), armW * 0.72, skin);

    // ── Torso ─────────────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - size.width * 0.255, bodyTop,
            cx + size.width * 0.255, bodyBot),
        const Radius.circular(10)),
      shirt,
    );

    // Belt
    canvas.drawRect(
      Rect.fromLTRB(cx - size.width * 0.255, bodyBot - 9,
          cx + size.width * 0.255, bodyBot - 2),
      belt,
    );

    // ── Neck ──────────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTRB(cx - size.width * 0.07, neckTop,
          cx + size.width * 0.07, neckBot),
      skin,
    );

    // ── Head ──────────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, headCY), headR, skin);

    // Hair top
    final hairPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, headCY), radius: headR * 1.02),
        math.pi, math.pi,
      )
      ..close();
    canvas.drawPath(hairPath, hair);

    // Sideburns
    canvas.drawRect(
        Rect.fromLTRB(cx - headR, headCY - 3, cx - headR + 5, headCY + 8),
        hair);
    canvas.drawRect(
        Rect.fromLTRB(cx + headR - 5, headCY - 3, cx + headR, headCY + 8),
        hair);

    // ── Eyes ──────────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx - headR * 0.33, headCY + 2), headR * 0.11, eye);
    canvas.drawCircle(Offset(cx + headR * 0.33, headCY + 2), headR * 0.11, eye);

    // Catchlights
    final cl = Paint()..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawCircle(Offset(cx - headR * 0.29, headCY + 0.5), headR * 0.04, cl);
    canvas.drawCircle(Offset(cx + headR * 0.37, headCY + 0.5), headR * 0.04, cl);

    // Eyebrows
    final brow = Paint()
      ..color = const Color(0xFF3D2314)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx - headR * 0.48, headCY - headR * 0.22),
        Offset(cx - headR * 0.18, headCY - headR * 0.17),
        brow);
    canvas.drawLine(
        Offset(cx + headR * 0.18, headCY - headR * 0.17),
        Offset(cx + headR * 0.48, headCY - headR * 0.22),
        brow);

    // Smile
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, headCY + headR * 0.26),
          width: headR * 0.72,
          height: headR * 0.36),
      0, math.pi, false,
      Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FullBodyAvatarPainter old) => false;
}

// ── Stats row (Streak / SS Coins / Friends — all gold numbers) ────────────

class _StatsRow extends StatelessWidget {
  final int streakDays, ssCoins, friendsCount;
  const _StatsRow(
      {required this.streakDays,
      required this.ssCoins,
      required this.friendsCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(value: '$streakDays', label: 'Streak'),
        _StatItem(value: '$ssCoins', label: 'SS Coins'),
        _StatItem(value: '$friendsCount', label: 'Friends'),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary)),
        const SizedBox(height: 1),
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.textSubtle,
                fontWeight: FontWeight.w500)),
      ],
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

// ── My Avatar tab ─────────────────────────────────────────────────────────

class _MyAvatarTab extends StatefulWidget {
  const _MyAvatarTab();
  @override
  State<_MyAvatarTab> createState() => _MyAvatarTabState();
}

class _MyAvatarTabState extends State<_MyAvatarTab> {
  int _catIndex = 0;

  static const List<String> _cats = [
    'My Avatar', 'Appearance', 'Hairstyles', 'Outfit',
    'Shoes', 'Accessories', 'Seasonal',
  ];

  static const List<List<String>> _itemNames = [
    ['Default', 'Athletic', 'Scholar', 'Traveller', 'Warrior', 'Elegant'],
    ['Light', 'Medium', 'Tan', 'Brown', 'Deep', 'Custom'],
    ['Short', 'Curly', 'Afro', 'Waves', 'Long', 'Braids'],
    ['Thoub', 'Casual', 'Formal', 'Sports', 'Abaya', 'Kimono'],
    ['Sandals', 'Sneakers', 'Formal', 'Boots', 'Slip-on', 'Bare'],
    ['Glasses', 'Keffiyeh', 'Cap', 'Backpack', 'Watch', 'Ring'],
    ['Ramadan', 'Eid', 'Hajj', 'Winter', 'Summer', 'Exclusive'],
  ];

  static const List<List<IconData>> _itemIcons = [
    [Icons.person_rounded, Icons.sports_rounded, Icons.menu_book_rounded,
     Icons.flight_rounded, Icons.shield_rounded, Icons.auto_awesome_rounded],
    [Icons.face_rounded, Icons.face_rounded, Icons.face_rounded,
     Icons.face_rounded, Icons.face_rounded, Icons.palette_rounded],
    [Icons.content_cut_rounded, Icons.waves_rounded, Icons.circle_rounded,
     Icons.water_drop_rounded, Icons.blur_on_rounded, Icons.auto_awesome_rounded],
    [Icons.checkroom_rounded, Icons.style_rounded, Icons.business_center_rounded,
     Icons.sports_rounded, Icons.shopping_bag_rounded, Icons.star_rounded],
    [Icons.directions_walk_rounded, Icons.sports_rounded, Icons.workspace_premium_rounded,
     Icons.hiking_rounded, Icons.nature_rounded, Icons.spa_rounded],
    [Icons.visibility_rounded, Icons.account_balance_wallet_rounded, Icons.sports_basketball_rounded,
     Icons.school_rounded, Icons.watch_rounded, Icons.diamond_rounded],
    [Icons.nightlight_round, Icons.celebration_rounded, Icons.mosque_rounded,
     Icons.ac_unit_rounded, Icons.wb_sunny_rounded, Icons.star_rounded],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Full-body avatar character
        SizedBox(
          height: 158,
          child: Center(
            child: SizedBox(
              width: 110,
              height: 158,
              child: CustomPaint(painter: _FullBodyAvatarPainter()),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Horizontal category scroll bar
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = i == _catIndex;
              return GestureDetector(
                onTap: () => setState(() => _catIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.primary.withValues(alpha: 0.12)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppTheme.primary : const Color(0xFF1F2D4A),
                      width: 1,
                    ),
                  ),
                  child: Text(_cats[i],
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.textSubtle)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Locked items grid
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: 6,
            itemBuilder: (_, i) => _LockedAvatarItem(
              icon: _itemIcons[_catIndex][i],
              name: _itemNames[_catIndex][i],
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedAvatarItem extends StatelessWidget {
  final IconData icon;
  final String name;
  const _LockedAvatarItem({required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F2D4A), width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 28, color: AppTheme.textSubtle),
                  const SizedBox(height: 5),
                  Text(name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSubtle)),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on_rounded,
                          size: 9, color: AppTheme.primary),
                      const SizedBox(width: 2),
                      Text('SS Coins',
                          style: GoogleFonts.outfit(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6, right: 6,
              child: Icon(Icons.lock_rounded, size: 12, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Salah Seasons tab ─────────────────────────────────────────────────────

class _SalahSeasonsTab extends StatelessWidget {
  const _SalahSeasonsTab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Winding path scene at 25% opacity
        Opacity(
          opacity: 0.25,
          child: SizedBox.expand(
            child: CustomPaint(painter: _SeasonPathPainter()),
          ),
        ),
        // Lock overlay — IgnorePointer so it doesn't block scroll events
        IgnorePointer(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 100,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Coming Soon',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Salah Seasons Launching Soon',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Season winding path painter ───────────────────────────────────────────

class _SeasonPathPainter extends CustomPainter {
  static const List<Offset> _nodes = [
    Offset(0.50, 0.93),
    Offset(0.25, 0.82),
    Offset(0.55, 0.71),
    Offset(0.75, 0.60),
    Offset(0.50, 0.49),
    Offset(0.25, 0.38),
    Offset(0.55, 0.27),
    Offset(0.75, 0.17),
    Offset(0.50, 0.08),
    Offset(0.50, 0.02),
  ];

  static const List<int> _milestoneValues = [
    5, 50, 150, 300, 500, 750, 1000, 1500, 2000, 2500
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawPath(canvas, size);
    for (int i = 0; i < _nodes.length; i++) {
      _drawNode(canvas, size, i);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Deep navy → dark purple gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0E3A), Color(0xFF0D1B3E)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final rng = math.Random(77);
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (int i = 0; i < 70; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.2 + 0.3;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
    final goldPaint = Paint()..color = AppTheme.primary.withValues(alpha: 0.7);
    for (int i = 0; i < 10; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 1.8, goldPaint);
    }
  }

  void _drawPath(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final first = Offset(_nodes[0].dx * size.width, _nodes[0].dy * size.height);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < _nodes.length; i++) {
      path.lineTo(
        _nodes[i].dx * size.width,
        _nodes[i].dy * size.height,
      );
    }
    canvas.drawPath(path, pathPaint);
  }

  void _drawNode(Canvas canvas, Size size, int i) {
    final pos = Offset(_nodes[i].dx * size.width, _nodes[i].dy * size.height);
    const nodeR = 26.0;

    // Alternate gold / teal fill: odd = primary (gold), even = accent (teal)
    final fill = i.isOdd ? AppTheme.primary : AppTheme.accent;

    // Filled circle
    canvas.drawCircle(pos, nodeR, Paint()..color = fill);

    // White border ring
    canvas.drawCircle(
      pos, nodeR,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Mini mosque silhouette in white
    _drawMiniMosque(canvas, pos, i);

    // Milestone label below node — white bold
    final tp = TextPainter(
      text: TextSpan(
        text: '${_milestoneValues[i]}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy + nodeR + 4));
  }

  void _drawMiniMosque(Canvas canvas, Offset c, int tier) {
    // Scale 0.55–1.0 as tier increases; fits within nodeR=26
    final s = (0.55 + tier / 9.0 * 0.45) * 9.5;
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    // Left minaret
    canvas.drawRect(
      Rect.fromLTRB(c.dx - s * 1.7, c.dy - s * 1.1, c.dx - s * 1.0, c.dy + s * 0.3),
      p,
    );
    // Pointed minaret top
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - s * 1.7, c.dy - s * 1.1)
        ..lineTo(c.dx - s * 1.35, c.dy - s * 1.75)
        ..lineTo(c.dx - s * 1.0, c.dy - s * 1.1)
        ..close(),
      p,
    );

    // Main building base
    canvas.drawRect(
      Rect.fromLTRB(c.dx - s * 0.85, c.dy - s * 0.25, c.dx + s * 0.85, c.dy + s * 0.5),
      p,
    );

    // Main dome
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(c.dx, c.dy - s * 0.25),
        width: s * 1.3, height: s * 1.0,
      ),
      math.pi, math.pi, false, p,
    );

    // Crescent for higher tiers (tier ≥ 4)
    if (tier >= 4) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c.dx, c.dy - s * 1.05),
          width: s * 0.5, height: s * 0.5,
        ),
        math.pi * 0.2, math.pi * 1.6, false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_SeasonPathPainter old) => false;
}

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
