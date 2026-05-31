import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';

// ── Dark map style ────────────────────────────────────────────────────────

const _kMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d1320"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#6B7A99"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#060810"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#7a8599"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#151e35"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#4a5568"}]},
  {"featureType":"road.arterial","elementType":"geometry.fill","stylers":[{"color":"#1a2440"}]},
  {"featureType":"road.highway","elementType":"geometry.fill","stylers":[{"color":"#1e2d4a"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#2a3d60"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#060810"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#253856"}]}
]
''';

// ── Data model ────────────────────────────────────────────────────────────

class _Mosque {
  final String id, name, vicinity;
  final LatLng location;
  final double distanceMiles;
  Map<String, String> prayerTimes = {};

  _Mosque({
    required this.id,
    required this.name,
    required this.vicinity,
    required this.location,
    required this.distanceMiles,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────

class MosquesScreen extends StatefulWidget {
  const MosquesScreen({super.key});
  @override
  State<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends State<MosquesScreen>
    with SingleTickerProviderStateMixin {
  final _mapCtrl = Completer<GoogleMapController>();

  LatLng? _userLoc;
  List<_Mosque> _mosques = [];
  _Mosque? _selected;
  Set<Marker> _markers = {};

  double _radiusMi = 1.0;
  static const _radii = [0.5, 1.0, 5.0, 10.0];

  Set<String> _savedIds = {};
  bool _loadingMosques = false;
  String? _apiKey;

  late final AnimationController _sheetAnim;
  late final Animation<Offset> _sheetSlide;

  static const _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    _sheetAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _sheetSlide = Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic));
    _init();
    // Sheet slides in on screen entry regardless of mosque data
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _sheetAnim.forward();
    });
  }

  @override
  void dispose() {
    _sheetAnim.dispose();
    super.dispose();
  }

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _savedIds = (prefs.getStringList('saved_mosques') ?? []).toSet();
    await _getLocation();
    await _fetchMosques();
  }

  Future<void> _getLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 8));
        if (mounted) {
          setState(() => _userLoc = LatLng(pos.latitude, pos.longitude));
        }
        return;
      }
    } catch (_) {}
    // Fallback: London
    if (mounted) setState(() => _userLoc = const LatLng(51.5074, -0.1278));
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchMosques() async {
    if (_userLoc == null || _apiKey == null) return;
    if (mounted) setState(() => _loadingMosques = true);

    try {
      final radiusM = (_radiusMi * 1609.34).round();
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_userLoc!.latitude},${_userLoc!.longitude}'
        '&radius=$radiusM&type=mosque&key=$_apiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw Exception('Places API ${res.statusCode}');

      final results =
          (jsonDecode(res.body)['results'] as List).cast<Map<String, dynamic>>();

      final mosques = results.map((r) {
        final loc = r['geometry']['location'];
        final latLng = LatLng(
            (loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
        final distM = Geolocator.distanceBetween(
          _userLoc!.latitude, _userLoc!.longitude,
          latLng.latitude, latLng.longitude,
        );
        return _Mosque(
          id: r['place_id'] as String,
          name: r['name'] as String,
          vicinity: (r['vicinity'] ?? '') as String,
          location: latLng,
          distanceMiles: distM / 1609.34,
        );
      }).toList()
        ..sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));

      if (mounted) {
        _mosques = mosques;
        await _buildMarkers();
        setState(() {
          _selected = _mosques.isNotEmpty ? _mosques[0] : null;
          _loadingMosques = false;
        });
        if (_selected != null) {
          _fetchPrayerTimes(_selected!);
          _animateCameraTo(_selected!.location);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMosques = false);
    }
  }

  Future<void> _fetchPrayerTimes(_Mosque mosque) async {
    try {
      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch ~/ 1000;
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings/$ts'
        '?latitude=${mosque.location.latitude}'
        '&longitude=${mosque.location.longitude}&method=3',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final timings =
          jsonDecode(res.body)['data']['timings'] as Map<String, dynamic>;
      final times = {
        for (final name in _prayerNames) name: _fmt24to12(timings[name] as String)
      };
      if (mounted) setState(() => mosque.prayerTimes = times);
    } catch (_) {}
  }

  String _fmt24to12(String s) {
    final parts = s.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  // ── Markers ───────────────────────────────────────────────────────────────

  Future<void> _buildMarkers() async {
    if (!mounted) return;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final futures = _mosques.asMap().entries.map((e) async {
      final i = e.key;
      final mosque = e.value;
      final isSaved = _savedIds.contains(mosque.id);
      final Color bg;
      if (isSaved) {
        bg = AppTheme.accent;
      } else if (i == 0) {
        bg = AppTheme.primary;
      } else {
        bg = const Color(0xFF5A6A85);
      }
      final icon = await _makePinBitmap(mosque.name, bg, dpr);
      return Marker(
        markerId: MarkerId(mosque.id),
        position: mosque.location,
        icon: icon,
        anchor: const Offset(0.5, 1.0),
        onTap: () => _selectMosque(mosque),
      );
    });
    final markers = await Future.wait(futures);
    if (mounted) setState(() => _markers = markers.toSet());
  }

  Future<BitmapDescriptor> _makePinBitmap(
      String label, Color bg, double dpr) async {
    const fs = 11.0;
    const hPad = 9.0;
    const vPad = 5.5;
    const radius = 8.0;
    const tailH = 7.0;

    final short = label.length > 20 ? '${label.substring(0, 19)}…' : label;

    final tp = TextPainter(
      text: TextSpan(
        text: short,
        style: const TextStyle(
            fontSize: fs,
            color: Colors.white,
            fontWeight: FontWeight.w600),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final bw = math.max(52.0, tp.width + hPad * 2);
    final bh = tp.height + vPad * 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, bw, bh), const Radius.circular(radius)),
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    // Bubble
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, bw, bh), const Radius.circular(radius)),
      Paint()..color = bg,
    );
    // Tail
    canvas.drawPath(
      Path()
        ..moveTo(bw / 2 - 5, bh)
        ..lineTo(bw / 2 + 5, bh)
        ..lineTo(bw / 2, bh + tailH)
        ..close(),
      Paint()..color = bg,
    );
    // Text
    tp.paint(canvas, Offset(hPad, vPad));

    final totalH = bh + tailH;
    final pic = recorder.endRecording();
    final img = await pic.toImage(
        (bw * dpr).ceil(), (totalH * dpr).ceil());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bd!.buffer.asUint8List(),
        imagePixelRatio: dpr);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _selectMosque(_Mosque mosque) async {
    setState(() => _selected = mosque);
    _animateCameraTo(mosque.location);
    if (mosque.prayerTimes.isEmpty) _fetchPrayerTimes(mosque);
  }

  void _animateCameraTo(LatLng loc) async {
    final ctrl = await _mapCtrl.future;
    ctrl.animateCamera(CameraUpdate.newLatLngZoom(loc, 15.5));
  }

  Future<void> _toggleSave() async {
    final mosque = _selected;
    if (mosque == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (_savedIds.contains(mosque.id)) {
      _savedIds.remove(mosque.id);
    } else {
      _savedIds.add(mosque.id);
    }
    await prefs.setStringList('saved_mosques', _savedIds.toList());
    await _buildMarkers();
    setState(() {});
  }

  Future<void> _getDirections() async {
    final mosque = _selected;
    if (mosque == null) return;
    final lat = mosque.location.latitude;
    final lng = mosque.location.longitude;
    final name = Uri.encodeComponent(mosque.name);
    final appleUri =
        Uri.parse('maps://?q=$name&ll=$lat,$lng&dirflg=d');
    final googleUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'
        '&destination_place_id=${mosque.id}');
    if (await canLaunchUrl(appleUri)) {
      await launchUrl(appleUri);
    } else {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    }
  }

  void _zoomIn() async {
    final c = await _mapCtrl.future;
    c.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() async {
    final c = await _mapCtrl.future;
    c.animateCamera(CameraUpdate.zoomOut());
  }

  void _locateMe() async {
    if (_userLoc == null) return;
    final c = await _mapCtrl.future;
    c.animateCamera(CameraUpdate.newLatLngZoom(_userLoc!, 14));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    const sheetFraction = 0.44;
    final sheetH = size.height * sheetFraction;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Mosques',
            style: TextStyle(color: AppTheme.textPrimary)),
        actions: [
          const BellIconButton(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: AppTheme.textSubtle,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _userLoc == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : Stack(
              children: [
                // Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLoc!,
                    zoom: 14,
                  ),
                  style: _kMapStyle,
                  onMapCreated: _mapCtrl.complete,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  padding: EdgeInsets.only(
                    top: topPad + kToolbarHeight,
                    bottom: sheetH + 48,
                    right: 64,
                  ),
                ),
                // Map controls
                Positioned(
                  top: topPad + kToolbarHeight + 16,
                  right: 16,
                  child: _MapControls(
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                    onLocate: _locateMe,
                  ),
                ),
                // Bottom panel
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SlideTransition(
                    position: _sheetSlide,
                    child: _BottomPanel(
                      mosques: _mosques,
                      selected: _selected,
                      savedIds: _savedIds,
                      loading: _loadingMosques,
                      radiusMi: _radiusMi,
                      radii: _radii,
                      onRadiusChanged: (r) {
                        setState(() => _radiusMi = r);
                        _fetchMosques();
                      },
                      onToggleSave: _toggleSave,
                      onGetDirections: _getDirections,
                      onMosqueTap: _selectMosque,
                      prayerNames: _prayerNames,
                    ),
                  ),
                ),
                // Loading overlay
                if (_loadingMosques)
                  Positioned(
                    bottom: sheetH + 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                    strokeWidth: 2)),
                            const SizedBox(width: 10),
                            Text('Finding mosques…',
                                style: TextStyle(
                                    color: AppTheme.textSubtle,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ── Map controls ──────────────────────────────────────────────────────────

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn, onZoomOut, onLocate;
  const _MapControls(
      {required this.onZoomIn,
      required this.onZoomOut,
      required this.onLocate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MapBtn(icon: Icons.add, onTap: onZoomIn),
        const SizedBox(height: 6),
        _MapBtn(icon: Icons.remove, onTap: onZoomOut),
        const SizedBox(height: 10),
        _MapBtn(icon: Icons.my_location_rounded, onTap: onLocate,
            color: AppTheme.primary),
      ],
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _MapBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1F2D4A)),
          boxShadow: [
            BoxShadow(
                color: Colors.black38, blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Icon(icon, size: 20, color: color ?? AppTheme.textPrimary),
      ),
    );
  }
}

// ── Bottom panel ──────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final List<_Mosque> mosques;
  final _Mosque? selected;
  final Set<String> savedIds;
  final bool loading;
  final double radiusMi;
  final List<double> radii;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onToggleSave, onGetDirections;
  final ValueChanged<_Mosque> onMosqueTap;
  final List<String> prayerNames;

  const _BottomPanel({
    required this.mosques,
    required this.selected,
    required this.savedIds,
    required this.loading,
    required this.radiusMi,
    required this.radii,
    required this.onRadiusChanged,
    required this.onToggleSave,
    required this.onGetDirections,
    required this.onMosqueTap,
    required this.prayerNames,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 24)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF2A3A5A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Radius pills
          _RadiusPills(
              radiusMi: radiusMi, radii: radii, onChanged: onRadiusChanged),
          const SizedBox(height: 12),
          // Content
          if (selected == null && !loading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                mosques.isEmpty
                    ? 'No mosques found in this area'
                    : 'Tap a pin to view details',
                style: TextStyle(color: AppTheme.textSubtle),
              ),
            )
          else if (selected != null)
            _MosqueDetail(
              mosque: selected!,
              isSaved: savedIds.contains(selected!.id),
              onToggleSave: onToggleSave,
              onGetDirections: onGetDirections,
              prayerNames: prayerNames,
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Radius pills ──────────────────────────────────────────────────────────

class _RadiusPills extends StatelessWidget {
  final double radiusMi;
  final List<double> radii;
  final ValueChanged<double> onChanged;
  const _RadiusPills(
      {required this.radiusMi,
      required this.radii,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: radii.map((r) {
          final selected = r == radiusMi;
          final label =
              r < 1 ? '${(r * 10).round() / 10} mi' : '${r.toInt()} mi';
          return GestureDetector(
            onTap: () => onChanged(r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : const Color(0xFF1A2440),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppTheme.primary : const Color(0xFF2A3A5A),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      selected ? AppTheme.primary : AppTheme.textSubtle,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Mosque detail card ────────────────────────────────────────────────────

class _MosqueDetail extends StatelessWidget {
  final _Mosque mosque;
  final bool isSaved;
  final VoidCallback onToggleSave, onGetDirections;
  final List<String> prayerNames;

  const _MosqueDetail({
    required this.mosque,
    required this.isSaved,
    required this.onToggleSave,
    required this.onGetDirections,
    required this.prayerNames,
  });

  String _currentPrayer() {
    final now = DateTime.now();
    if (mosque.prayerTimes.isEmpty) return '';
    String current = '';
    for (final name in prayerNames) {
      final t = mosque.prayerTimes[name];
      if (t == null) continue;
      final dt = _parseTime(t, now);
      if (dt.isBefore(now)) current = name;
    }
    return current;
  }

  DateTime _parseTime(String t, DateTime now) {
    // e.g. "5:30 AM"
    final fmt = DateFormat('h:mm a');
    final parsed = fmt.parse(t);
    return DateTime(now.year, now.month, now.day, parsed.hour, parsed.minute);
  }

  @override
  Widget build(BuildContext context) {
    final activePrayer = _currentPrayer();
    final distStr = mosque.distanceMiles < 0.1
        ? '${(mosque.distanceMiles * 5280).round()} ft away'
        : '${mosque.distanceMiles.toStringAsFixed(1)} miles away';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mosque.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 13, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          distStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (mosque.vicinity.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          mosque.vicinity,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSubtle
                                  .withValues(alpha: 0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.mosque_rounded,
                    color: AppTheme.primary, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Prayer time chips
          if (mosque.prayerTimes.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: prayerNames.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final name = prayerNames[i];
                  final time = mosque.prayerTimes[name] ?? '—';
                  final isActive = name == activePrayer;
                  return _PrayerChip(
                      name: name, time: time, isActive: isActive);
                },
              ),
            )
          else
            SizedBox(
              height: 52,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onGetDirections,
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Get Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onToggleSave,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSaved
                        ? AppTheme.primary.withValues(alpha: 0.15)
                        : const Color(0xFF1A2440),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSaved
                          ? AppTheme.primary
                          : const Color(0xFF2A3A5A),
                      width: isSaved ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(
                    isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSaved ? AppTheme.primary : AppTheme.textSubtle,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Prayer chip ───────────────────────────────────────────────────────────

class _PrayerChip extends StatelessWidget {
  final String name, time;
  final bool isActive;
  const _PrayerChip(
      {required this.name, required this.time, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primary.withValues(alpha: 0.15)
            : const Color(0xFF1A2440),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppTheme.primary : const Color(0xFF2A3A5A),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.primary : AppTheme.textSubtle,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isActive ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
