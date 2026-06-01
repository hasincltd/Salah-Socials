import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';

part 'widgets/greeting_row.dart';
part 'widgets/next_prayer_card.dart';
part 'widgets/prayer_list.dart';
part 'widgets/streak_chip.dart';
part 'widgets/home_painters.dart';
part 'widgets/streak_revive_dialog.dart';

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

    final reviveUsed = prefs.getBool(_kReviveUsed) ?? false;
    if (reviveUsed && restoredCount > 0) {
      if (mounted) setState(() => _revivedStreak = restoredCount);
      return;
    }

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

    final prevCount = lostAtMs != null
        ? (prefs.getInt(_kRevivePrevCount) ?? 0)
        : _computeStreakBeforeMiss(prefs);

    if (prevCount == 0) return;

    if (lostAtMs == null) {
      lostAtMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_kReviveLostAtMs, lostAtMs);
      await prefs.setInt(_kRevivePrevCount, prevCount);
      await prefs.setBool(_kReviveUsed, false);
    }

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
          AnimatedBuilder(
            animation: _starAnim,
            builder: (_, _) => CustomPaint(
              painter: _StarfieldPainter(_stars, _starAnim.value),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: CustomPaint(
              painter: _MosquePainter(),
              size: const Size(double.infinity, 110),
            ),
          ),
          Positioned(
            top: 160,
            right: 28,
            child: CustomPaint(
              painter: _CrescentPainter(),
              size: const Size(30, 30),
            ),
          ),
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
