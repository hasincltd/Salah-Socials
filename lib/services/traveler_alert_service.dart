import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Incremented when the user taps a traveler alert notification.
// MainNavigation listens to this to switch to the Mosques tab.
final travelAlertTabTrigger = ValueNotifier<int>(0);

// ── TravelerAlertService ──────────────────────────────────────────────────

class TravelerAlertService {
  TravelerAlertService._();

  // SharedPreferences keys
  static const _kEnabled      = 'settings_traveler_alerts';
  static const _kHomeLatKey   = 'home_latitude';
  static const _kHomeLngKey   = 'home_longitude';
  static const _kFiredPrefix  = 'traveler_fired_'; // + prayerName_yyyy-mm-dd
  static const kPendingMosque = 'traveler_alert_mosque_id';

  static const _homeRadiusMiles  = 2.0;
  static const _alertWindowMins  = 30;
  static const _searchRadiusM    = 8047; // ~5 miles

  static const _prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static final _plugin = FlutterLocalNotificationsPlugin();
  static Timer? _timer;

  // Populated when notification fires; read by MosquesScreen on tap.
  static String? pendingMosqueId;

  // ── Init ─────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    // Request iOS permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  static void start() {
    _timer?.cancel();
    _check(); // run once immediately on start
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _check());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Notification tap handler ──────────────────────────────────────────────

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      pendingMosqueId = payload;
    }
    travelAlertTabTrigger.value++;
  }

  // ── Check logic ───────────────────────────────────────────────────────────

  static Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();

    // Respect the toggle
    if (!(prefs.getBool(_kEnabled) ?? true)) return;

    // Need a home location to compare against
    final homeLat = prefs.getDouble(_kHomeLatKey);
    final homeLng = prefs.getDouble(_kHomeLngKey);
    if (homeLat == null || homeLng == null) return;

    // Get current GPS position
    final Position pos;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      return;
    }

    // Must be more than 2 miles from home
    final distFromHome = Geolocator.distanceBetween(
          homeLat, homeLng,
          pos.latitude, pos.longitude,
        ) /
        1609.34;
    if (distFromHome < _homeRadiusMiles) return;

    // Fetch prayer times for current location
    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch ~/ 1000;
    final Map<String, DateTime> prayerTimes;
    try {
      final uri = Uri.parse(
        'https://api.aladhan.com/v1/timings/$ts'
        '?latitude=${pos.latitude}&longitude=${pos.longitude}&method=3',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final timings =
          jsonDecode(res.body)['data']['timings'] as Map<String, dynamic>;
      prayerTimes = {};
      for (final name in _prayerNames) {
        final parts = (timings[name] as String).split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        prayerTimes[name] =
            DateTime(now.year, now.month, now.day, h, m);
      }
    } catch (_) {
      return;
    }

    // Find a prayer within the next 30 minutes
    String? targetPrayer;
    for (final entry in prayerTimes.entries) {
      final mins = entry.value.difference(now).inMinutes;
      if (mins >= 0 && mins <= _alertWindowMins) {
        targetPrayer = entry.key;
        break;
      }
    }
    if (targetPrayer == null) return;

    // Fire only once per prayer per day
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}'
        '-${now.day.toString().padLeft(2, '0')}';
    final firedKey = '$_kFiredPrefix${targetPrayer}_$today';
    if (prefs.getBool(firedKey) ?? false) return;

    // Find nearest mosque via Google Places API
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return;

    String mosqueName = 'a nearby mosque';
    String mosqueId   = '';
    double mosqueMiles = 0;
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${pos.latitude},${pos.longitude}'
        '&radius=$_searchRadiusM&type=mosque&key=$apiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final results = (jsonDecode(res.body)['results'] as List)
            .cast<Map<String, dynamic>>();
        if (results.isNotEmpty) {
          final r = results[0];
          mosqueName = r['name'] as String;
          mosqueId   = r['place_id'] as String;
          final loc  = r['geometry']['location'];
          mosqueMiles = Geolocator.distanceBetween(
                pos.latitude, pos.longitude,
                (loc['lat'] as num).toDouble(),
                (loc['lng'] as num).toDouble(),
              ) /
              1609.34;
        }
      }
    } catch (_) {}

    // Build notification body
    final distStr = mosqueMiles < 0.1
        ? 'nearby'
        : '${mosqueMiles.toStringAsFixed(1)} miles away';
    final body =
        "It's almost $targetPrayer time — $mosqueName is $distStr. "
        "Want directions? 🕌";

    // Store pending mosque for MosquesScreen pre-selection
    if (mosqueId.isNotEmpty) {
      pendingMosqueId = mosqueId;
      await prefs.setString(kPendingMosque, mosqueId);
    }

    // Show the notification
    await _plugin.show(
      id: targetPrayer.hashCode,
      title: 'Prayer Time Alert',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'traveler_alerts',
          'Traveler Alerts',
          channelDescription:
              'Alerts when you are away from home near prayer time',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: mosqueId,
    );

    await prefs.setBool(firedKey, true);
  }
}
