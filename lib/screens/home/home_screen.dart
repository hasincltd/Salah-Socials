import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';

// ── Hijri conversion (Fātimid algorithm) ─────────────────────────────────

const _hijriMonths = [
  'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani",
  'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban",
  'Ramadan', 'Shawwal', "Dhul Qa'dah", 'Dhul Hijjah',
];

({int year, int month, int day}) _toHijri(DateTime g) {
  int y = g.year, m = g.month, d = g.day;
  int jd = (1461 * (y + 4800 + (m - 14) ~/ 12)) ~/ 4 +
      (367 * (m - 2 - 12 * ((m - 14) ~/ 12))) ~/ 12 -
      (3 * ((y + 4900 + (m - 14) ~/ 12) ~/ 100)) ~/ 4 +
      d - 32075;
  int l = jd - 1948440 + 10632;
  int n = (l - 1) ~/ 10631;
  l = l - 10631 * n + 354;
  int j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
      (l ~/ 5670) * ((43 * l) ~/ 15238);
  l = l - ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) + 29;
  int hm = (24 * l) ~/ 709;
  int hd = l - (709 * hm) ~/ 24;
  int hy = 30 * n + j - 30;
  return (year: hy, month: hm, day: hd);
}

// ── Data models ───────────────────────────────────────────────────────────

class _Prayer {
  final String name;
  final DateTime time;
  final Color dot;
  const _Prayer(this.name, this.time, this.dot);
}

class _Star {
  final double x, y, size, phase, maxOpacity;
  const _Star(this.x, this.y, this.size, this.phase, this.maxOpacity);
}

// ── Screen ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _starAnim;
  late final AnimationController _pulseAnim;
  late final List<_Star> _stars;

  List<_Prayer> _prayers = [];
  int _nextIdx = -1;
  int _currIdx = -1;
  Duration _remaining = Duration.zero;
  Timer? _tick;

  bool _loading = true;
  bool _hasError = false;

  Map<String, bool> _prayerLogs = {};
  Map<int, bool> _weekLogs = {};  // weekday 1–7 → all 5 prayers logged that day
  int _streakDays = 0;
  int _revivedStreak = 0;
  int _prevStreakCount = 0;
  int _ssCoins = 0;
  bool _revivePopupShownThisSession = false;

  static const _kReviveLostAtMs      = 'streak_revive_lost_at_ms';
  static const _kRevivePrevCount     = 'streak_revive_prev_count';
  static const _kReviveUsed          = 'streak_revive_used';
  static const _kReviveRestoredCount = 'streak_revive_restored_count';
  static const _kSsCoins             = 'ss_coin_balance';
  static const _kReviveCost          = 250;
  static const _kSsCoinsDefault      = 1000;

  static const _fallbackLat = 51.5074;
  static const _fallbackLon = -0.1278;

  static const _names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const _dots = [
    Color(0xFF5B9BD5),
    Color(0xFFD4A847),
    Color(0xFFE8A87C),
    Color(0xFFFF7675),
    Color(0xFF9B8FD5),
  ];

  @override
  void initState() {
    super.initState();
    _starAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    final rng = math.Random(42);
    _stars = List.generate(
      72,
      (_) => _Star(rng.nextDouble(), rng.nextDouble() * 0.60,
          0.6 + rng.nextDouble() * 1.8, rng.nextDouble(),
          0.25 + rng.nextDouble() * 0.6),
    );

    _loadPrayers();
    _loadPrayerLogs();
  }

  @override
  void dispose() {
    _starAnim.dispose();
    _pulseAnim.dispose();
    _tick?.cancel();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  Future<void> _loadPrayers() async {
    if (mounted) setState(() { _loading = true; _hasError = false; });
    try {
      double lat = _fallbackLat, lon = _fallbackLon;
      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.low),
          ).timeout(const Duration(seconds: 6));
          lat = pos.latitude;
          lon = pos.longitude;
        }
      } catch (_) {}

      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch ~/ 1000;
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings/$ts'
        '?latitude=$lat&longitude=$lon&method=3',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final timings =
          jsonDecode(res.body)['data']['timings'] as Map<String, dynamic>;
      _prayers = [
        for (var i = 0; i < _names.length; i++)
          _Prayer(
            _names[i],
            _parseTime(timings[_names[i]] as String, now),
            _dots[i],
          ),
      ];

      _recompute();
      _startTick();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  DateTime _parseTime(String s, DateTime now) {
    final p = s.split(':');
    return DateTime(now.year, now.month, now.day,
        int.parse(p[0]), int.parse(p[1]));
  }

  void _recompute() {
    final now = DateTime.now();
    _nextIdx = _prayers.indexWhere((p) => p.time.isAfter(now));
    _currIdx = _nextIdx > 0
        ? _nextIdx - 1
        : _nextIdx == -1
            ? _prayers.length - 1
            : -1;
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _recompute();
      final now = DateTime.now();
      final target = _nextIdx >= 0
          ? _prayers[_nextIdx].time
          : _prayers[0].time.add(const Duration(days: 1));
      final diff = target.difference(now);
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
    });
  }

  // ── Prayer log persistence ────────────────────────────────────────────────

  String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String _prefKey(String dateKey, String name) => 'prayer_log_${dateKey}_$name';

  Future<void> _loadPrayerLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final dk = _todayKey();
    final logs = {for (final n in _names) n: prefs.getBool(_prefKey(dk, n)) ?? false};

    // Current-week dots: Monday of this week → Sunday. Future days stay false.
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekLogs = <int, bool>{};
    for (int i = 1; i <= 7; i++) {
      final dayDate = monday.add(Duration(days: i - 1));
      final dayDk = DateFormat('yyyy-MM-dd').format(dayDate);
      weekLogs[i] = _names.every((n) => prefs.getBool(_prefKey(dayDk, n)) == true);
    }

    if (!mounted) return;
    setState(() {
      _prayerLogs = logs;
      _weekLogs = weekLogs;
      _streakDays = _computeStreak(prefs);
    });
    await _checkStreakRevive(prefs);
  }

  int _computeStreak(SharedPreferences prefs) {
    var day = DateTime.now();
    // If today isn't fully logged yet, start the count from yesterday so an
    // in-progress day doesn't wipe out the existing streak.
    final todayDk = DateFormat('yyyy-MM-dd').format(day);
    if (!_names.every((n) => prefs.getBool(_prefKey(todayDk, n)) == true)) {
      day = day.subtract(const Duration(days: 1));
    }
    int streak = 0;
    for (int i = 0; i < 365; i++) {
      final dk = DateFormat('yyyy-MM-dd').format(day);
      if (_names.every((n) => prefs.getBool(_prefKey(dk, n)) == true)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _togglePrayer(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefKey(_todayKey(), name);
    await prefs.setBool(key, !(prefs.getBool(key) ?? false));
    await _loadPrayerLogs();
  }

  // ── Streak revive ─────────────────────────────────────────────────────────

  int _computeStreakBeforeMiss(SharedPreferences prefs) {
    int streak = 0;
    var day = DateTime.now().subtract(const Duration(days: 1));
    for (int i = 0; i < 365; i++) {
      final dk = DateFormat('yyyy-MM-dd').format(day);
      if (_names.every((n) => prefs.getBool(_prefKey(dk, n)) == true)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _checkStreakRevive(SharedPreferences prefs) async {
    if (!mounted) return;

    _ssCoins = prefs.getInt(_kSsCoins) ?? _kSsCoinsDefault;
    final restoredCount = prefs.getInt(_kReviveRestoredCount) ?? 0;

    if (_streakDays > 0) {
      // Natural streak recovered — retire the revive override once caught up.
      if (restoredCount > 0 && _streakDays >= restoredCount) {
        await prefs.remove(_kReviveRestoredCount);
        await prefs.remove(_kReviveLostAtMs);
        await prefs.remove(_kRevivePrevCount);
        await prefs.setBool(_kReviveUsed, false);
        if (mounted) setState(() => _revivedStreak = 0);
      } else if (restoredCount > 0) {
        if (mounted) setState(() => _revivedStreak = restoredCount);
      }
      return;
    }

    // Natural streak = 0.

    // If revive was already used this miss window, show restored count.
    final reviveUsed = prefs.getBool(_kReviveUsed) ?? false;
    if (reviveUsed && restoredCount > 0) {
      if (mounted) setState(() => _revivedStreak = restoredCount);
      return;
    }

    // Expire any stale revive window older than 24 hours.
    var lostAtMs = prefs.getInt(_kReviveLostAtMs);
    if (lostAtMs != null) {
      final age = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(lostAtMs));
      if (age.inHours >= 24) {
        await prefs.remove(_kReviveLostAtMs);
        await prefs.remove(_kRevivePrevCount);
        await prefs.setBool(_kReviveUsed, false);
        await prefs.remove(_kReviveRestoredCount);
        lostAtMs = null;
      }
    }

    // Determine previous streak (before miss).
    final prevCount = lostAtMs != null
        ? (prefs.getInt(_kRevivePrevCount) ?? 0)
        : _computeStreakBeforeMiss(prefs);

    if (prevCount == 0) return; // no streak to revive

    // Record new miss if not already recorded.
    if (lostAtMs == null) {
      lostAtMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_kReviveLostAtMs, lostAtMs);
      await prefs.setInt(_kRevivePrevCount, prevCount);
      await prefs.setBool(_kReviveUsed, false);
    }

    // Show popup — once per session only.
    if (_revivePopupShownThisSession) return;
    _revivePopupShownThisSession = true;
    if (mounted) setState(() => _prevStreakCount = prevCount);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showRevivePopupDialog();
    });
  }

  void _showRevivePopupDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogCtx) => _StreakReviveDialog(
        previousStreak: _prevStreakCount,
        ssCoins: _ssCoins,
        reviveCost: _kReviveCost,
        onRevive: _doRevive,
        onDismiss: () => Navigator.of(dialogCtx).pop(),
      ),
    );
  }

  Future<void> _doRevive() async {
    Navigator.of(context).pop();
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    final newBalance = math.max(0, _ssCoins - _kReviveCost);
    await prefs.setInt(_kSsCoins, newBalance);
    await prefs.setBool(_kReviveUsed, true);
    await prefs.setInt(_kReviveRestoredCount, _prevStreakCount);
    if (!mounted) return;
    setState(() {
      _ssCoins = newBalance;
      _revivedStreak = _prevStreakCount;
    });
  }

  // ── Computed props ────────────────────────────────────────────────────────

  String get _countdownStr {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _communityPrayerName {
    if (_currIdx >= 0 && _currIdx < _prayers.length) {
      return _prayers[_currIdx].name;
    }
    return 'Isha';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = _toHijri(now);
    final hijriStr = '${h.day} ${_hijriMonths[h.month - 1]} ${h.year} AH';
    final gregStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              hijriStr,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.primary,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              gregStr,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppTheme.textSubtle,
              ),
            ),
          ],
        ),
        actions: [
          const BellIconButton(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            color: AppTheme.textSubtle,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Starfield
          AnimatedBuilder(
            animation: _starAnim,
            builder: (_, _) => CustomPaint(
              painter: _StarfieldPainter(_stars, _starAnim.value),
              child: const SizedBox.expand(),
            ),
          ),
          // Mosque silhouette
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _MosquePainter(),
              size: const Size(double.infinity, 110),
            ),
          ),
          // Crescent moon
          Positioned(
            top: 160,
            right: 28,
            child: CustomPaint(
              painter: _CrescentPainter(),
              size: const Size(30, 30),
            ),
          ),
          // Content
          SafeArea(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _hasError
                    ? _buildError()
                    : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.textSubtle),
          const SizedBox(height: 12),
          Text('Could not load prayer times',
              style: GoogleFonts.outfit(color: AppTheme.textSubtle)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadPrayers, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // After all today's prayers have started (_nextIdx == -1), surface
    // tomorrow's Fajr so the hero card is always visible.
    final _Prayer? next;
    if (_nextIdx >= 0) {
      next = _prayers[_nextIdx];
    } else if (_prayers.isNotEmpty) {
      next = _Prayer(
        _prayers[0].name,
        _prayers[0].time.add(const Duration(days: 1)),
        _prayers[0].dot,
      );
    } else {
      next = null;
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 32),
      children: [
        _GreetingRow(greeting: _greeting),
        const SizedBox(height: 22),
        if (next != null) ...[
          _HeroPrayerCard(
            prayer: next,
            countdownStr: _countdownStr,
            communityName: _communityPrayerName,
            pulseAnim: _pulseAnim,
          ),
          const SizedBox(height: 18),
        ],
        _PrayerListCard(
          prayers: _prayers,
          pulseAnim: _pulseAnim,
          prayerLogs: _prayerLogs,
          onToggle: _togglePrayer,
        ),
        const SizedBox(height: 18),
        _StreakChip(
          streakDays: math.max(_streakDays, _revivedStreak),
          todayWeekday: DateTime.now().weekday,
          weekLogs: _weekLogs,
        ),
      ],
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────

class _StarfieldPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;
  _StarfieldPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final s in stars) {
      final phase = (t + s.phase) % 1.0;
      final opacity = s.maxOpacity * math.pow(math.sin(math.pi * phase), 2).toDouble();
      p.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
          Offset(s.x * size.width, s.y * size.height), s.size, p);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter o) => o.t != t;
}

class _MosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Base
    canvas.drawRect(Rect.fromLTWH(cx - 95, h * 0.52, 190, h * 0.48), p);

    // Main dome
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, h * 0.52), width: 136, height: 94),
      math.pi, math.pi, true, p,
    );

    // Side domes
    for (final dx in [-62.0, 62.0]) {
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx + dx, h * 0.60), width: 58, height: 42),
        math.pi, math.pi, true, p,
      );
    }

    // Minarets
    for (final mx in [-132.0, 132.0]) {
      canvas.drawRect(Rect.fromLTWH(cx + mx - 6, h * 0.08, 12, h * 0.92), p);
      final tip = Path()
        ..moveTo(cx + mx - 10, h * 0.08)
        ..lineTo(cx + mx, 0)
        ..lineTo(cx + mx + 10, h * 0.08)
        ..close();
      canvas.drawPath(tip, p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _CrescentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.20);
    final r = size.width / 2;
    final outer = Path()
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r));
    final inner = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(r + r * 0.52, r - r * 0.12), radius: r * 0.80));
    canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

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

// ── Hero prayer card ──────────────────────────────────────────────────────

class _HeroPrayerCard extends StatelessWidget {
  final _Prayer prayer;
  final String countdownStr;
  final String communityName;
  final AnimationController pulseAnim;

  const _HeroPrayerCard({
    required this.prayer,
    required this.countdownStr,
    required this.communityName,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(prayer.time);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface, Color(0xFF0D1525)],
        ),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.14),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(
              children: [
                Text(
                  'NEXT PRAYER',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prayer.name,
                  style: GoogleFonts.outfit(
                    fontSize: 44,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textPrimary,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countdownStr,
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 3,
                  ).copyWith(
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Begins at $timeStr',
                  style: GoogleFonts.outfit(
                      fontSize: 13, color: AppTheme.textSubtle),
                ),
              ],
            ),
          ),
          // Community pulse strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.07),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.12)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: pulseAnim,
                  builder: (_, _) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent
                              .withValues(alpha: 0.65 * pulseAnim.value),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '47 people nearby just prayed $communityName',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Prayer list ───────────────────────────────────────────────────────────

class _PrayerListCard extends StatelessWidget {
  final List<_Prayer> prayers;
  final AnimationController pulseAnim;
  final Map<String, bool> prayerLogs;
  final void Function(String) onToggle;

  const _PrayerListCard({
    required this.prayers,
    required this.pulseAnim,
    required this.prayerLogs,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2D4A)),
      ),
      child: Column(
        children: List.generate(prayers.length, (i) {
          // Window is open when the prayer has started AND the next prayer
          // hasn't started yet (Isha has no upper bound within the same day).
          final windowOpen = !prayers[i].time.isAfter(now) &&
              (i == prayers.length - 1 || prayers[i + 1].time.isAfter(now));
          return _PrayerRow(
            prayer: prayers[i],
            isCurrent: windowOpen,
            isCompleted: !prayers[i].time.isAfter(now) && !windowOpen,
            isLogged: prayerLogs[prayers[i].name] ?? false,
            isLast: i == prayers.length - 1,
            onTap: windowOpen ? () => onToggle(prayers[i].name) : null,
            pulseAnim: pulseAnim,
          );
        }),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final _Prayer prayer;
  final bool isCurrent, isCompleted, isLogged, isLast;
  final VoidCallback? onTap;
  final AnimationController pulseAnim;

  const _PrayerRow({
    required this.prayer,
    required this.isCurrent,
    required this.isCompleted,
    required this.isLogged,
    required this.isLast,
    this.onTap,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(prayer.time);
    final Widget row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrent
            ? (isLogged
                ? AppTheme.accent.withValues(alpha: 0.08)
                : AppTheme.primary.withValues(alpha: 0.08))
            : Colors.transparent,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : BorderRadius.zero,
        border: isLast
            ? null
            : const Border(
                bottom:
                    BorderSide(color: Color(0xFF192036), width: 0.5)),
      ),
      child: Row(
        children: [
          // Dot — pulsing when window open (gold unlogged, green logged); coloured otherwise.
          if (isCurrent)
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, _) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLogged ? AppTheme.accent : AppTheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (isLogged ? AppTheme.accent : AppTheme.primary)
                          .withValues(alpha: 0.75 * pulseAnim.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: prayer.dot,
              ),
            ),
          const SizedBox(width: 14),
          // Name
          Expanded(
            child: Text(
              prayer.name,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: isCurrent
                    ? (isLogged ? AppTheme.accent : AppTheme.primary)
                    : AppTheme.textPrimary,
              ),
            ),
          ),
          // Time
          Text(
            timeStr,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isCurrent
                  ? (isLogged ? AppTheme.accent : AppTheme.primary)
                  : AppTheme.textSubtle,
            ),
          ),
          const SizedBox(width: 12),
          // Log circle — four distinct states.
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLogged
                    ? Colors.green.withValues(alpha: 0.18)
                    : Colors.transparent,
                border: Border.all(
                  color: isLogged
                      ? Colors.green
                      : isCurrent
                          ? AppTheme.primary
                          : isCompleted
                              ? AppTheme.textSubtle
                              : const Color(0xFF1F2D4A),
                  width: 1.5,
                ),
              ),
              child: isLogged
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.green)
                  : null,
            ),
          ),
        ],
      ),
    );

    // State 1a: logged AND window still open → full opacity (prayer in progress).
    // State 1b: logged AND window closed → 50% opacity (prayer complete).
    if (isLogged && !isCurrent) return Opacity(opacity: 0.5, child: row);
    // State 3: missed (window closed, not logged) → 40% opacity.
    if (isCompleted) return Opacity(opacity: 0.4, child: row);
    // State 2 (current) and state 4 (future) → full opacity.
    return row;
  }
}

// ── Streak chip ───────────────────────────────────────────────────────────

class _StreakChip extends StatelessWidget {
  final int streakDays;
  final int todayWeekday; // Dart: 1=Mon, 7=Sun
  final Map<int, bool> weekLogs; // weekday 1–7 → all 5 prayers logged

  const _StreakChip({
    required this.streakDays,
    required this.todayWeekday,
    required this.weekLogs,
  });

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2D4A)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '$streakDays',
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Day Streak',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _DayDot(
                  label: dayLabels[i],
                  dayNum: i + 1,
                  todayWeekday: todayWeekday,
                  isDone: weekLogs[i + 1] ?? false,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final int dayNum;
  final int todayWeekday;
  final bool isDone; // true only when all 5 prayers were logged that day

  const _DayDot({
    required this.label,
    required this.dayNum,
    required this.todayWeekday,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = dayNum == todayWeekday;

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: isToday
                ? AppTheme.primary
                : isDone
                    ? AppTheme.primary.withValues(alpha: 0.7)
                    : AppTheme.textSubtle.withValues(alpha: 0.35),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppTheme.primary : Colors.transparent,
            border: isToday
                ? Border.all(color: AppTheme.primary, width: 2)
                : isDone
                    ? null
                    : Border.all(
                        color: AppTheme.textSubtle.withValues(alpha: 0.2),
                        width: 1),
          ),
          child: isDone
              ? const Icon(Icons.check_rounded,
                  size: 15, color: AppTheme.onPrimary)
              : isToday
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : null,
        ),
      ],
    );
  }
}

// ── Streak Revive Dialog ──────────────────────────────────────────────────

class _StreakReviveDialog extends StatelessWidget {
  final int previousStreak;
  final int ssCoins;
  final int reviveCost;
  final VoidCallback onRevive;
  final VoidCallback onDismiss;

  const _StreakReviveDialog({
    required this.previousStreak,
    required this.ssCoins,
    required this.reviveCost,
    required this.onRevive,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = ssCoins >= reviveCost;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.40),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Flame icon
            const Text('🔥', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 14),
            Text(
              'Streak Revive Available',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'You missed a day, but your $previousStreak-day streak\ncan still be saved!',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSubtle,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Before → Missed → Revived bubbles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StreakBubble(
                    count: previousStreak, label: 'Before', state: _BubbleState.active),
                _Arrow(),
                _StreakBubble(
                    count: 0, label: 'Missed', state: _BubbleState.missed),
                _Arrow(),
                _StreakBubble(
                    count: previousStreak, label: 'Revived', state: _BubbleState.revived),
              ],
            ),
            const SizedBox(height: 22),
            // Coin balance pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 7),
                  Text(
                    'Balance: $ssCoins SS Coins',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Revive button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canAfford ? onRevive : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor:
                      AppTheme.primary.withValues(alpha: 0.25),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  canAfford
                      ? 'Revive for $reviveCost SS Coins'
                      : 'Not enough SS Coins ($reviveCost needed)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: canAfford
                        ? AppTheme.onPrimary
                        : AppTheme.textSubtle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Dismiss
            TextButton(
              onPressed: onDismiss,
              child: Text(
                'Maybe later',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSubtle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BubbleState { active, missed, revived }

class _Arrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.arrow_forward_rounded,
            size: 18, color: AppTheme.textSubtle.withValues(alpha: 0.5)),
      );
}

class _StreakBubble extends StatelessWidget {
  final int count;
  final String label;
  final _BubbleState state;

  const _StreakBubble({
    required this.count,
    required this.label,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (state) {
      case _BubbleState.active:
        color = AppTheme.primary;
      case _BubbleState.missed:
        color = AppTheme.textSubtle;
      case _BubbleState.revived:
        color = AppTheme.accent;
    }

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(
              color: color.withValues(alpha: state == _BubbleState.missed ? 0.25 : 0.5),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}
