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
import '../../widgets/profile_avatar.dart';
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

  String _displayName = 'Hasin';
  Map<String, bool> _prayerLogs = {};
  int _streakDays = 0;
  int _revivedStreak = 0;
  int _prevStreakCount = 0;
  int _ssCoins = 0;
  bool _revivePopupShownThisSession = false;

  // Prayer list date navigation
  DateTime? _viewDate; // null = today
  final bool _isPremium = false;
  Map<String, bool> _viewLogs = {};
  List<_Prayer> _viewPrayers = []; // fetched times for future days
  bool _viewLoading = false;
  double? _cachedLat;
  double? _cachedLon;

  // Streak chip week navigation
  int _weekOffset = 0; // 0 = current week, positive = weeks back
  List<String> _weekViewLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  List<bool> _weekViewDone = const [false, false, false, false, false, false, false];
  int? _weekViewTodayIndex;

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

  Future<List<_Prayer>> _fetchPrayerTimings(
      DateTime date, double lat, double lon) async {
    final noon = DateTime(date.year, date.month, date.day, 12);
    final ts = noon.millisecondsSinceEpoch ~/ 1000;
    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timings/$ts'
      '?latitude=$lat&longitude=$lon&method=3',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final timings =
        jsonDecode(res.body)['data']['timings'] as Map<String, dynamic>;
    return [
      for (var i = 0; i < _names.length; i++)
        _Prayer(_names[i], _parseTime(timings[_names[i]] as String, date), _dots[i]),
    ];
  }

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

      _cachedLat = lat;
      _cachedLon = lon;

      _prayers = await _fetchPrayerTimings(DateTime.now(), lat, lon);
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

    final (labels, done, todayIdx) = _buildWeekView(_weekOffset, prefs);

    if (!mounted) return;
    setState(() {
      _displayName = prefs.getString('settings_display_name') ?? 'Hasin';
      _prayerLogs = logs;
      _streakDays = _computeStreak(prefs);
      _weekViewLabels = labels;
      _weekViewDone = done;
      _weekViewTodayIndex = todayIdx;
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

  // ── Prayer list date navigation ───────────────────────────────────────────

  int get _daysFromToday {
    if (_viewDate == null) return 0;
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final viewNorm =
        DateTime(_viewDate!.year, _viewDate!.month, _viewDate!.day);
    return viewNorm.difference(todayNorm).inDays;
  }

  bool get _isViewingToday => _daysFromToday == 0;
  bool get _isViewingFuture => _daysFromToday > 0;

  int get _maxHistoryDays => _isPremium ? 30 : 7;

  bool get _canGoPrev => _daysFromToday > -(_maxHistoryDays - 1);
  bool get _canGoNext => _daysFromToday < 7;

  Future<void> _goToPrevDay() async {
    if (!_canGoPrev) return;
    final base = _viewDate ?? DateTime.now();
    final prev = base.subtract(const Duration(days: 1));
    await _navigateToDate(DateTime(prev.year, prev.month, prev.day));
  }

  Future<void> _goToNextDay() async {
    if (!_canGoNext) return;
    final base = _viewDate ?? DateTime.now();
    final next = base.add(const Duration(days: 1));
    await _navigateToDate(DateTime(next.year, next.month, next.day));
  }

  Future<void> _navigateToDate(DateTime date) async {
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final dateNorm = DateTime(date.year, date.month, date.day);

    if (dateNorm.isAtSameMomentAs(todayNorm)) {
      setState(() {
        _viewDate = null;
        _viewLogs = {};
        _viewPrayers = [];
      });
      return;
    }

    if (dateNorm.isAfter(todayNorm)) {
      // Future day — fetch prayer times from API
      setState(() {
        _viewDate = date;
        _viewLoading = true;
        _viewPrayers = [];
        _viewLogs = {};
      });
      await _loadFuturePrayers(date);
      return;
    }

    // Past day — read logs from SharedPreferences; use today's prayer times
    final prefs = await SharedPreferences.getInstance();
    final dk = DateFormat('yyyy-MM-dd').format(date);
    final logs = {
      for (final n in _names) n: prefs.getBool(_prefKey(dk, n)) ?? false
    };
    if (!mounted) return;
    setState(() {
      _viewDate = date;
      _viewLogs = logs;
      _viewPrayers = [];
    });
  }

  Future<void> _loadFuturePrayers(DateTime date) async {
    try {
      final prayers = await _fetchPrayerTimings(
        date, _cachedLat ?? _fallbackLat, _cachedLon ?? _fallbackLon);
      if (!mounted) return;
      setState(() { _viewPrayers = prayers; _viewLoading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _viewLoading = false);
    }
  }

  Future<void> _toggleViewPrayer(String name) async {
    if (_viewDate == null || !_isPremium) return;
    final prefs = await SharedPreferences.getInstance();
    final dk = DateFormat('yyyy-MM-dd').format(_viewDate!);
    final key = _prefKey(dk, name);
    await prefs.setBool(key, !(prefs.getBool(key) ?? false));
    if (!mounted) return;
    final updatedLogs = {
      for (final n in _names) n: prefs.getBool(_prefKey(dk, n)) ?? false
    };
    setState(() => _viewLogs = updatedLogs);
  }

  // ── Streak chip week navigation ───────────────────────────────────────────

  int get _maxWeekOffset => _isPremium ? 5 : 2;

  (List<String>, List<bool>, int?) _buildWeekView(
      int offset, SharedPreferences prefs) {
    final now = DateTime.now();
    final monday =
        now.subtract(Duration(days: now.weekday - 1 + offset * 7));
    final todayNorm = DateTime(now.year, now.month, now.day);
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final labels = <String>[];
    final done = <bool>[];
    int? todayIdx;
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      labels.add(offset == 0 ? letters[i] : '${day.day}');
      final dk = DateFormat('yyyy-MM-dd').format(day);
      done.add(_names.every((n) => prefs.getBool(_prefKey(dk, n)) == true));
      final dayNorm = DateTime(day.year, day.month, day.day);
      if (dayNorm == todayNorm) todayIdx = i;
    }
    return (labels, done, todayIdx);
  }

  Future<void> _changeWeekOffset(int delta) async {
    final newOffset = _weekOffset + delta;
    if (newOffset < 0 || newOffset > _maxWeekOffset) return;
    final prefs = await SharedPreferences.getInstance();
    final (labels, done, todayIdx) = _buildWeekView(newOffset, prefs);
    if (!mounted) return;
    setState(() {
      _weekOffset = newOffset;
      _weekViewLabels = labels;
      _weekViewDone = done;
      _weekViewTodayIndex = todayIdx;
    });
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
    final displayDate = _viewDate ?? DateTime.now();
    final h = _toHijri(displayDate);
    final hijriStr = '${h.day} ${_hijriMonths[h.month - 1]} ${h.year} AH';
    final gregStr = DateFormat('EEEE, d MMMM yyyy').format(displayDate);

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DateNavArrow(
              icon: Icons.chevron_left_rounded,
              enabled: _canGoPrev,
              onTap: _goToPrevDay,
            ),
            const SizedBox(width: 6),
            Column(
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
            const SizedBox(width: 6),
            _DateNavArrow(
              icon: Icons.chevron_right_rounded,
              enabled: _canGoNext,
              onTap: _goToNextDay,
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
    if (_viewLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    final prayers =
        _isViewingFuture ? _viewPrayers : _prayers;
    final prayerLogs = _isViewingToday ? _prayerLogs : _viewLogs;
    final onToggle = _isViewingToday ? _togglePrayer : _toggleViewPrayer;

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
        _GreetingRow(greeting: _greeting, displayName: _displayName),
        const SizedBox(height: 22),
        if (_isViewingToday) ...[
          if (next != null) ...[
            _HeroPrayerCard(
              prayer: next,
              countdownStr: _countdownStr,
              communityName: _communityPrayerName,
              pulseAnim: _pulseAnim,
            ),
            const SizedBox(height: 18),
          ],
        ] else if (_isViewingFuture) ...[
          _DayFutureMessage(viewDate: _viewDate!),
          const SizedBox(height: 18),
        ] else ...[
          _DayCompletionMessage(viewLogs: _viewLogs),
          const SizedBox(height: 18),
        ],
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v > 200) _goToPrevDay();
            if (v < -200) _goToNextDay();
          },
          child: _PrayerListCard(
            prayers: prayers,
            pulseAnim: _pulseAnim,
            prayerLogs: prayerLogs,
            onToggle: onToggle,
            isToday: _isViewingToday,
            isPremiumRetroactive: !_isViewingFuture && _isPremium,
            isFuture: _isViewingFuture,
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v > 200) _changeWeekOffset(1);
            if (v < -200) _changeWeekOffset(-1);
          },
          child: _StreakChip(
            streakDays: math.max(_streakDays, _revivedStreak),
            dayLabels: _weekViewLabels,
            dayDone: _weekViewDone,
            todayIndex: _weekViewTodayIndex,
          ),
        ),
      ],
    );
  }
}

// ── Date navigation arrow ─────────────────────────────────────────────────

class _DateNavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _DateNavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        child: Icon(
          icon,
          size: 24,
          color: enabled
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.3),
        ),
      );
}

// ── Day completion message ────────────────────────────────────────────────

class _DayCompletionMessage extends StatelessWidget {
  final Map<String, bool> viewLogs;

  const _DayCompletionMessage({required this.viewLogs});

  @override
  Widget build(BuildContext context) {
    final completed = viewLogs.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2D4A)),
      ),
      child: Center(
        child: Text(
          completed == 5
              ? '🎉 Congratulations — all 5 prayers completed!'
              : '✨ $completed/5 prayers completed — keep going!',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Future day header message ─────────────────────────────────────────────

class _DayFutureMessage extends StatelessWidget {
  final DateTime viewDate;

  const _DayFutureMessage({required this.viewDate});

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('EEEE, d MMMM').format(viewDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2D4A)),
      ),
      child: Center(
        child: Text(
          '📅 Prayer times for $label',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
