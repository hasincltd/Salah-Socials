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
import 'package:google_fonts/google_fonts.dart';
import '../../services/traveler_alert_service.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';
import '../notifications/notifications_screen.dart';

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
    debugPrint('[Geocode] API key prefix: ${_apiKey == null ? "NULL" : _apiKey!.substring(0, _apiKey!.length.clamp(0, 8))}');
    if (query.isEmpty || _apiKey == null) return;
    setState(() => _geocoding = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent('$query, UK')}'
        '&key=$_apiKey',
      );
      debugPrint('[Geocode] URL: $uri');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      debugPrint('[Geocode] Status code: ${res.statusCode}');
      debugPrint('[Geocode] Body: ${res.body}');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      debugPrint('[Geocode] data[status]: ${data['status']}');
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
    } catch (e) {
      debugPrint('[Geocode] Exception: $e');
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

// ── Location bar ──────────────────────────────────────────────────────────

class _LocationBar extends StatelessWidget {
  final bool anchoredToGps;
  final bool showAddressInput;
  final VoidCallback onCurrentLocation;
  final VoidCallback onChooseAddress;

  const _LocationBar({
    required this.anchoredToGps,
    required this.showAddressInput,
    required this.onCurrentLocation,
    required this.onChooseAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1F2D4A), width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Current Location pill
          Expanded(
            child: GestureDetector(
              onTap: onCurrentLocation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: anchoredToGps
                      ? AppTheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.my_location_rounded,
                        size: 14,
                        color: anchoredToGps
                            ? AppTheme.primary
                            : AppTheme.textSubtle),
                    const SizedBox(width: 5),
                    Text('Current Location',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: anchoredToGps
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: anchoredToGps
                                ? AppTheme.primary
                                : AppTheme.textSubtle)),
                  ],
                ),
              ),
            ),
          ),
          // Divider
          Container(
              width: 1,
              height: 22,
              color: const Color(0xFF1F2D4A)),
          // Choose Address pill
          Expanded(
            child: GestureDetector(
              onTap: onChooseAddress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !anchoredToGps || showAddressInput
                      ? AppTheme.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded,
                        size: 14,
                        color: !anchoredToGps || showAddressInput
                            ? AppTheme.primary
                            : AppTheme.textSubtle),
                    const SizedBox(width: 5),
                    Text('Choose Address',
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: !anchoredToGps || showAddressInput
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: !anchoredToGps || showAddressInput
                                ? AppTheme.primary
                                : AppTheme.textSubtle)),
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

// ── Address input panel ───────────────────────────────────────────────────

class _AddressInputPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSubmit;

  const _AddressInputPanel({
    required this.controller,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2D4A), width: 1),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter postcode or address…',
                hintStyle: GoogleFonts.outfit(
                    color: AppTheme.textSubtle, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            onTap: loading ? null : onSubmit,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded,
                      color: AppTheme.primary, size: 18),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

// ── Search this area banner ───────────────────────────────────────────────

class _SearchThisAreaBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchThisAreaBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45,
                blurRadius: 10,
                offset: Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_rounded,
                color: AppTheme.primary, size: 15),
            const SizedBox(width: 6),
            Text('Search this area',
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
          ],
        ),
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
        _MapBtn(
            icon: Icons.my_location_rounded,
            onTap: onLocate,
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
          boxShadow: const [
            BoxShadow(
                color: Colors.black38,
                blurRadius: 8,
                offset: Offset(0, 2))
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
                style: GoogleFonts.outfit(color: AppTheme.textSubtle),
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
                style: GoogleFonts.outfit(
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
                      style: GoogleFonts.outfit(
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
                          style: GoogleFonts.outfit(
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
                          style: GoogleFonts.outfit(
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
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
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
                  label: Text('Get Directions',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Favourite star — green when saved
              GestureDetector(
                onTap: onToggleSave,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSaved
                        ? _kFavouriteGreen.withValues(alpha: 0.15)
                        : const Color(0xFF1A2440),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSaved
                          ? _kFavouriteGreen
                          : const Color(0xFF2A3A5A),
                      width: isSaved ? 1.5 : 1,
                    ),
                  ),
                  child: Icon(
                    isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSaved ? _kFavouriteGreen : AppTheme.textSubtle,
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
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? AppTheme.primary : AppTheme.textSubtle,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            time,
            style: GoogleFonts.outfit(
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

// ── Directions action sheet ───────────────────────────────────────────────

class _DirectionsSheet extends StatelessWidget {
  final Uri appleUri;
  final Uri googleUri;
  final Uri wazeUri;
  final bool googleAvailable;
  final bool wazeAvailable;
  final bool usingCustomOrigin;

  const _DirectionsSheet({
    required this.appleUri,
    required this.googleUri,
    required this.wazeUri,
    required this.googleAvailable,
    required this.wazeAvailable,
    required this.usingCustomOrigin,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A3A5A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Get Directions',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _DirectionOption(
              icon: Icons.map_rounded,
              label: 'Apple Maps',
              available: true,
              onTap: () {
                Navigator.pop(context);
                launchUrl(appleUri);
              },
            ),
            const SizedBox(height: 8),
            _DirectionOption(
              icon: Icons.navigation_rounded,
              label: 'Google Maps',
              available: googleAvailable,
              onTap: googleAvailable
                  ? () {
                      Navigator.pop(context);
                      launchUrl(googleUri,
                          mode: LaunchMode.externalApplication);
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            _DirectionOption(
              icon: Icons.route_rounded,
              label: 'Waze',
              subtitle: usingCustomOrigin
                  ? 'Routes from your current GPS location'
                  : null,
              available: wazeAvailable,
              onTap: wazeAvailable
                  ? () {
                      Navigator.pop(context);
                      launchUrl(wazeUri,
                          mode: LaunchMode.externalApplication);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool available;
  final VoidCallback? onTap;

  const _DirectionOption({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: available ? 1.0 : 0.35,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2440),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A3A5A)),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 22,
                  color: available
                      ? AppTheme.primary
                      : AppTheme.textSubtle),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: available
                            ? AppTheme.textPrimary
                            : AppTheme.textSubtle,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: AppTheme.textSubtle),
                      ),
                  ],
                ),
              ),
              if (!available)
                Text(
                  'Not installed',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppTheme.textSubtle),
                )
              else
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppTheme.textSubtle),
            ],
          ),
        ),
      ),
    );
  }
}
