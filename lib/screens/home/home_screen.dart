import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';

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
  int _streakDays = 0;

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
    if (!mounted) return;
    setState(() {
      _prayerLogs = logs;
      _streakDays = _computeStreak(prefs);
    });
  }

  int _computeStreak(SharedPreferences prefs) {
    int streak = 0;
    var day = DateTime.now();
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
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {},
            color: AppTheme.textSubtle,
          ),
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
    final next = _nextIdx >= 0 ? _prayers[_nextIdx] : null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 8, 20, 32),
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
          nextIdx: _nextIdx,
          currIdx: _currIdx,
          pulseAnim: _pulseAnim,
          prayerLogs: _prayerLogs,
          onToggle: _togglePrayer,
        ),
        const SizedBox(height: 18),
        _StreakChip(
          streakDays: _streakDays,
          todayWeekday: DateTime.now().weekday,
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
  final int nextIdx;
  final int currIdx;
  final AnimationController pulseAnim;
  final Map<String, bool> prayerLogs;
  final void Function(String) onToggle;

  const _PrayerListCard({
    required this.prayers,
    required this.nextIdx,
    required this.currIdx,
    required this.pulseAnim,
    required this.prayerLogs,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2D4A)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < prayers.length; i++)
            _PrayerRow(
              prayer: prayers[i],
              isCurrent: i == currIdx,
              isCompleted: i < currIdx,
              isLogged: prayerLogs[prayers[i].name] ?? false,
              isLast: i == prayers.length - 1,
              onTap: i == currIdx ? () => onToggle(prayers[i].name) : null,
              pulseAnim: pulseAnim,
            ),
        ],
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
    final textColor = isCompleted
        ? AppTheme.textSubtle.withValues(alpha: 0.45)
        : isCurrent
            ? AppTheme.primary
            : AppTheme.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primary.withValues(alpha: 0.07)
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
          // Dot
          if (isCurrent)
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, _) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary
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
                color: isCompleted
                    ? prayer.dot.withValues(alpha: 0.35)
                    : prayer.dot.withValues(alpha: 0.85),
              ),
            ),
          const SizedBox(width: 14),
          // Name
          Expanded(
            child: Text(
              prayer.name,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight:
                    isCurrent ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ),
          // Time
          Text(
            timeStr,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: isCompleted
                  ? AppTheme.textSubtle.withValues(alpha: 0.4)
                  : isCurrent
                      ? AppTheme.primary
                      : AppTheme.textSubtle,
            ),
          ),
          const SizedBox(width: 12),
          // Log circle
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLogged
                    ? AppTheme.accent.withValues(alpha: 0.18)
                    : isCurrent
                        ? AppTheme.primary.withValues(alpha: 0.10)
                        : Colors.transparent,
                border: Border.all(
                  color: isLogged
                      ? AppTheme.accent
                      : isCurrent
                          ? AppTheme.primary.withValues(alpha: 0.35)
                          : isCompleted
                              ? const Color(0xFF283550).withValues(alpha: 0.40)
                              : const Color(0xFF283550),
                  width: 1.5,
                ),
              ),
              child: isLogged
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: AppTheme.accent)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak chip ───────────────────────────────────────────────────────────

class _StreakChip extends StatelessWidget {
  final int streakDays;
  final int todayWeekday; // Dart: 1=Mon, 7=Sun

  const _StreakChip(
      {required this.streakDays, required this.todayWeekday});

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

  const _DayDot(
      {required this.label,
      required this.dayNum,
      required this.todayWeekday});

  @override
  Widget build(BuildContext context) {
    final isToday = dayNum == todayWeekday;
    final isPast = dayNum < todayWeekday;

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
            color: isToday
                ? AppTheme.primary
                : isPast
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
            color: isPast ? AppTheme.primary : Colors.transparent,
            border: isToday
                ? Border.all(color: AppTheme.primary, width: 2)
                : isPast
                    ? null
                    : Border.all(
                        color: AppTheme.textSubtle.withValues(alpha: 0.2),
                        width: 1),
          ),
          child: isPast
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
