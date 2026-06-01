import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/traveler_alert_service.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';

part 'widgets/mosque_map_overlays.dart';
part 'widgets/mosque_bottom_panel.dart';

// ── Constants ─────────────────────────────────────────────────────────────

const _kSearchThresholdMiles = 1.0;
const _kFavouriteGreen = Color(0xFF34D399);

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

  // Location state
  LatLng? _userLoc;    // actual GPS position
  LatLng? _anchorLoc;  // search anchor (GPS or chosen address)
  LatLng? _mapCenter;  // current map camera centre (updated via onCameraMove)
  bool _anchoredToGps = true;

  // Address-input state
  bool _showAddressInput = false;
  final _addressCtrl = TextEditingController();
  bool _geocoding = false;
  Marker? _chosenLocMarker; // gold pin shown while anchored to a searched address

  // Search-this-area banner
  bool _showSearchBanner = false;

  // Mosque data
  List<_Mosque> _mosques = [];
  _Mosque? _selected;
  Set<Marker> _markers = {};
  Set<String> _savedIds = {};
  bool _loadingMosques = false;
  String? _apiKey;

  double _radiusMi = 1.0;
  static const _radii = [0.5, 1.0, 5.0, 10.0];

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
        .animate(
            CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic));
    _init();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _sheetAnim.forward();
    });
    travelAlertTabTrigger.addListener(_onTravelAlertTap);
  }

  @override
  void dispose() {
    travelAlertTabTrigger.removeListener(_onTravelAlertTap);
    _sheetAnim.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // Called when user taps a traveler alert notification.
  // Re-anchors to GPS, fetches fresh results, pre-selects the mosque.
  void _onTravelAlertTap() {
    final mosqueId = TravelerAlertService.pendingMosqueId;
    TravelerAlertService.pendingMosqueId = null;
    if (mosqueId == null || !mounted) return;
    _handleTravelAlertSelection(mosqueId);
  }

  Future<void> _handleTravelAlertSelection(String mosqueId) async {
    _chosenLocMarker = null;
    setState(() {
      _anchoredToGps = true;
      _showAddressInput = false;
      _showSearchBanner = false;
    });
    await _getLocation();
    await _fetchMosques();
    if (!mounted) return;
    _Mosque? match;
    for (final m in _mosques) {
      if (m.id == mosqueId) { match = m; break; }
    }
    if (match != null) await _selectMosque(match);
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
          setState(() {
            _userLoc = LatLng(pos.latitude, pos.longitude);
            _anchorLoc = _userLoc;
            _mapCenter = _userLoc;
          });
        }
        return;
      }
    } catch (_) {}
    // Fallback: London
    if (mounted) {
      setState(() {
        _userLoc = const LatLng(51.5074, -0.1278);
        _anchorLoc = _userLoc;
        _mapCenter = _userLoc;
      });
    }
  }

  // ── Camera tracking ───────────────────────────────────────────────────────

  void _onCameraMove(CameraPosition pos) {
    _mapCenter = pos.target;
  }

  void _onCameraIdle() {
    final center = _mapCenter;
    final anchor = _anchorLoc;
    if (center == null || anchor == null || !mounted) return;
    final distMiles = Geolocator.distanceBetween(
          anchor.latitude, anchor.longitude,
          center.latitude, center.longitude,
        ) /
        1609.34;
    final shouldShow = distMiles > _kSearchThresholdMiles;
    if (shouldShow != _showSearchBanner) {
      setState(() => _showSearchBanner = shouldShow);
    }
  }

  // ── API calls ─────────────────────────────────────────────────────────────

  Future<void> _fetchMosques() async {
    final center = _anchorLoc ?? _userLoc;
    if (center == null || _apiKey == null) return;
    if (mounted) setState(() => _loadingMosques = true);

    try {
      final radiusM = (_radiusMi * 1609.34).round();
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${center.latitude},${center.longitude}'
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
          center.latitude, center.longitude,
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
          _selected = null;
          _loadingMosques = false;
        });
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
        for (final name in _prayerNames)
          name: _fmt24to12(timings[name] as String)
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

  // ── Geocoding (Choose Address) ─────────────────────────────────────────────

  Future<void> _geocodeAndReanchor(String address) async {
    final query = address.trim();
    if (query.isEmpty || _apiKey == null) return;
    setState(() => _geocoding = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent('$query, UK')}'
        '&key=$_apiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        if (mounted) _showAddressNotFoundSnackBar();
        return;
      }
      final loc =
          (data['results'][0] as Map<String, dynamic>)['geometry']['location'];
      final latLng = LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );
      if (mounted) {
        _chosenLocMarker = Marker(
          markerId: const MarkerId('_chosen_location'),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        );
        setState(() {
          _anchorLoc = latLng;
          _anchoredToGps = false;
          _showAddressInput = false;
          _showSearchBanner = false;
        });
        _addressCtrl.clear();
        await _fetchMosques();
        if (!mounted) return;
        final ctrl = await _mapCtrl.future;
        ctrl.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
        if (mounted && _mosques.isEmpty) _showNoMosquesDialog();
      }
    } catch (_) {
      if (mounted) _showAddressNotFoundSnackBar();
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  void _showAddressNotFoundSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        'Address not found — please try a different postcode or address',
        style: GoogleFonts.outfit(color: AppTheme.textPrimary),
      ),
      backgroundColor: AppTheme.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Search this area ──────────────────────────────────────────────────────

  Future<void> _searchThisArea() async {
    final center = _mapCenter;
    if (center == null) return;
    setState(() {
      _anchorLoc = center;
      _anchoredToGps = false;
      _showSearchBanner = false;
    });
    await _fetchMosques();
    if (mounted && _mosques.isEmpty && !_loadingMosques) {
      _showNoMosquesDialog();
    }
  }

  void _showNoMosquesDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'No Mosques Found in This Area',
          style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        content: Text(
          'No mosques were found nearby. Try expanding your radius or searching a different location.',
          style: GoogleFonts.outfit(
              color: AppTheme.textSubtle, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK',
                style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Location controls ─────────────────────────────────────────────────────

  Future<void> _switchToCurrentLocation() async {
    if (_userLoc == null) return;
    _chosenLocMarker = null;
    setState(() {
      _anchorLoc = _userLoc;
      _anchoredToGps = true;
      _showAddressInput = false;
      _showSearchBanner = false;
    });
    _addressCtrl.clear();
    final ctrl = await _mapCtrl.future;
    ctrl.animateCamera(CameraUpdate.newLatLngZoom(_userLoc!, 14));
    await _fetchMosques();
  }

  // ── Radius change ─────────────────────────────────────────────────────────

  Future<void> _onRadiusChanged(double r) async {
    setState(() => _radiusMi = r);
    await _fetchMosques();
    final loc = _anchorLoc ?? _userLoc;
    if (loc == null) return;
    final ctrl = await _mapCtrl.future;
    ctrl.animateCamera(CameraUpdate.newLatLngZoom(loc, 14));
  }

  // ── Markers ───────────────────────────────────────────────────────────────

  Future<void> _buildMarkers() async {
    if (!mounted) return;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final futures = _mosques.map((mosque) async {
      final isSaved = _savedIds.contains(mosque.id);
      final isSelected = _selected?.id == mosque.id;

      // Pin colour: green (saved) > gold (selected) > grey (default)
      final Color bg;
      if (isSaved) {
        bg = _kFavouriteGreen;
      } else if (isSelected) {
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
    if (mounted) {
      setState(() {
        _markers = {
          ...markers,
          ?_chosenLocMarker,
        };
      });
    }
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
            fontSize: fs, color: Colors.white, fontWeight: FontWeight.w600),
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
    final img =
        await pic.toImage((bw * dpr).ceil(), (totalH * dpr).ceil());
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bd!.buffer.asUint8List(),
        imagePixelRatio: dpr);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _selectMosque(_Mosque mosque) async {
    setState(() => _selected = mosque);
    // Rebuild markers so previous pin returns to default/green and new is gold
    await _buildMarkers();
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
    if (mosque == null || !mounted) return;
    final mLat = mosque.location.latitude;
    final mLng = mosque.location.longitude;

    // Origin: chosen address when in address mode, GPS otherwise
    final origin = _anchoredToGps ? _userLoc : _anchorLoc;
    final oLat   = origin?.latitude;
    final oLng   = origin?.longitude;

    final Uri appleUri;
    final Uri googleUri;
    if (oLat != null && oLng != null) {
      appleUri  = Uri.parse(
          'maps://maps.apple.com/?saddr=$oLat,$oLng&daddr=$mLat,$mLng');
      googleUri = Uri.parse(
          'comgooglemaps://?saddr=$oLat,$oLng&daddr=$mLat,$mLng'
          '&directionsmode=walking');
    } else {
      appleUri  = Uri.parse('maps://maps.apple.com/?daddr=$mLat,$mLng');
      googleUri = Uri.parse(
          'comgooglemaps://?daddr=$mLat,$mLng&directionsmode=walking');
    }
    // Waze does not support a custom origin — it always routes from current GPS
    final wazeUri = Uri.parse('waze://?ll=$mLat,$mLng&navigate=yes');

    final googleAvailable = await canLaunchUrl(googleUri);
    final wazeAvailable   = await canLaunchUrl(wazeUri);

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DirectionsSheet(
        appleUri: appleUri,
        googleUri: googleUri,
        wazeUri: wazeUri,
        googleAvailable: googleAvailable,
        wazeAvailable: wazeAvailable,
        usingCustomOrigin: !_anchoredToGps && oLat != null,
      ),
    );
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
    final loc = _anchoredToGps ? _userLoc : _anchorLoc;
    if (loc == null) return;
    final c = await _mapCtrl.future;
    c.animateCamera(CameraUpdate.newLatLngZoom(loc, 14));
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
                // ── Map ──────────────────────────────────────────────────
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLoc!,
                    zoom: 14,
                  ),
                  style: _kMapStyle,
                  onMapCreated: _mapCtrl.complete,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  padding: EdgeInsets.zero,
                ),

                // ── Location bar + search banner (top-left overlay) ────
                Positioned(
                  top: topPad + kToolbarHeight + 8,
                  left: 16,
                  right: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Location source pills
                      _LocationBar(
                        anchoredToGps: _anchoredToGps,
                        showAddressInput: _showAddressInput,
                        onCurrentLocation: _switchToCurrentLocation,
                        onChooseAddress: () => setState(() {
                          _showAddressInput = !_showAddressInput;
                        }),
                      ),
                      // Address input panel
                      if (_showAddressInput) ...[
                        const SizedBox(height: 8),
                        _AddressInputPanel(
                          controller: _addressCtrl,
                          loading: _geocoding,
                          onSubmit: () =>
                              _geocodeAndReanchor(_addressCtrl.text),
                        ),
                      ],
                      // Search this area banner
                      if (_showSearchBanner) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: _SearchThisAreaBanner(
                              onTap: _searchThisArea),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Map controls (top-right) ──────────────────────────
                Positioned(
                  top: topPad + kToolbarHeight + 8,
                  right: 16,
                  child: _MapControls(
                    onZoomIn: _zoomIn,
                    onZoomOut: _zoomOut,
                    onLocate: _locateMe,
                  ),
                ),

                // ── Bottom panel ──────────────────────────────────────
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
                      onRadiusChanged: _onRadiusChanged,
                      onToggleSave: _toggleSave,
                      onGetDirections: _getDirections,
                      onMosqueTap: _selectMosque,
                      prayerNames: _prayerNames,
                    ),
                  ),
                ),

                // ── Loading overlay ───────────────────────────────────
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
                                style: GoogleFonts.outfit(
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
