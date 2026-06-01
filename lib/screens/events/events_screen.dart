import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../notifications/notifications_screen.dart';

part 'widgets/event_header.dart';
part 'widgets/event_card.dart';
part 'widgets/event_dialogs.dart';
part 'widgets/event_screens.dart';

// ── Shared date formatter ─────────────────────────────────────────────────

String _formatEventDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = DateTime(dt.year, dt.month, dt.day).difference(today).inDays;
  final dayStr = diff == 0
      ? 'Today'
      : diff == 1
          ? 'Tomorrow'
          : DateFormat('EEE, d MMM').format(dt);
  return '$dayStr · ${DateFormat('h:mm a').format(dt)}';
}

// ── Category enum ─────────────────────────────────────────────────────────

enum _Category { quran, youth, islamicStudy, sisters, community }

extension _CategoryX on _Category {
  String get label {
    switch (this) {
      case _Category.quran:        return 'Quran';
      case _Category.youth:        return 'Youth';
      case _Category.islamicStudy: return 'Islamic Study';
      case _Category.sisters:      return 'Sisters';
      case _Category.community:    return 'Community';
    }
  }

  Color get color {
    switch (this) {
      case _Category.quran:        return const Color(0xFF2DD4A0);
      case _Category.youth:        return const Color(0xFF9B59F5);
      case _Category.islamicStudy: return const Color(0xFFF59E0B);
      case _Category.sisters:      return const Color(0xFFEC4899);
      case _Category.community:    return const Color(0xFF3B82F6);
    }
  }
}

// ── Data model ────────────────────────────────────────────────────────────

class _Event {
  final String id;
  final String title;
  final String mosqueName;
  final _Category category;
  final bool isFree;
  final double? price;
  final double distanceMi;
  final DateTime dateTime;
  final int attendees;
  final bool isFeatured;
  final List<Color> avatarColors;

  const _Event({
    required this.id,
    required this.title,
    required this.mosqueName,
    required this.category,
    required this.isFree,
    this.price,
    required this.distanceMi,
    required this.dateTime,
    required this.attendees,
    required this.isFeatured,
    required this.avatarColors,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────

List<_Event> _buildMockEvents() {
  final now = DateTime.now();
  return [
    _Event(
      id: '1',
      title: 'Quran Recitation Circle',
      mosqueName: 'Masjid Al-Noor',
      category: _Category.quran,
      isFree: true,
      distanceMi: 0.3,
      dateTime: DateTime(now.year, now.month, now.day, 20, 30),
      attendees: 24,
      isFeatured: true,
      avatarColors: [Color(0xFF2DD4A0), Color(0xFFD4A847), Color(0xFF9B59F5)],
    ),
    _Event(
      id: '2',
      title: 'Quran Memorisation Workshop',
      mosqueName: 'Masjid Al-Furqan',
      category: _Category.quran,
      isFree: true,
      distanceMi: 0.5,
      dateTime: DateTime(now.year, now.month, now.day, 18, 0)
          .add(const Duration(days: 1)),
      attendees: 15,
      isFeatured: false,
      avatarColors: [Color(0xFF3B82F6), Color(0xFFEC4899)],
    ),
    _Event(
      id: '3',
      title: 'Youth Weekly Halaqa',
      mosqueName: 'Islamic Society East',
      category: _Category.youth,
      isFree: true,
      distanceMi: 0.7,
      dateTime: DateTime(now.year, now.month, now.day, 19, 0)
          .add(const Duration(days: 2)),
      attendees: 18,
      isFeatured: false,
      avatarColors: [
        Color(0xFF9B59F5), Color(0xFF2DD4A0), Color(0xFFF59E0B),
      ],
    ),
    _Event(
      id: '4',
      title: 'Fiqh of Worship — Study Circle',
      mosqueName: 'East London Mosque',
      category: _Category.islamicStudy,
      isFree: true,
      distanceMi: 1.2,
      dateTime: DateTime(now.year, now.month, now.day, 18, 30)
          .add(const Duration(days: 3)),
      attendees: 31,
      isFeatured: true,
      avatarColors: [
        Color(0xFFF59E0B), Color(0xFF3B82F6), Color(0xFF2DD4A0),
        Color(0xFFEC4899),
      ],
    ),
    _Event(
      id: '5',
      title: 'Sisters Tafseer Gathering',
      mosqueName: 'Masjid Ibn Battuta',
      category: _Category.sisters,
      isFree: true,
      distanceMi: 1.6,
      dateTime: DateTime(now.year, now.month, now.day, 16, 0)
          .add(const Duration(days: 1)),
      attendees: 12,
      isFeatured: false,
      avatarColors: [Color(0xFFEC4899), Color(0xFF9B59F5)],
    ),
    _Event(
      id: '6',
      title: 'Community Iftar Night',
      mosqueName: 'Central Mosque',
      category: _Category.community,
      isFree: true,
      distanceMi: 2.8,
      dateTime: DateTime(now.year, now.month, now.day, 19, 45),
      attendees: 89,
      isFeatured: true,
      avatarColors: [
        Color(0xFF3B82F6), Color(0xFFD4A847), Color(0xFF2DD4A0),
        Color(0xFF9B59F5),
      ],
    ),
    _Event(
      id: '7',
      title: 'Youth Football & Dua Evening',
      mosqueName: 'Al-Rahma Community Centre',
      category: _Category.youth,
      isFree: true,
      distanceMi: 3.5,
      dateTime: DateTime(now.year, now.month, now.day, 15, 0)
          .add(const Duration(days: 4)),
      attendees: 22,
      isFeatured: false,
      avatarColors: [Color(0xFF9B59F5), Color(0xFFF59E0B)],
    ),
    _Event(
      id: '8',
      title: 'Sisters Self-Care & Sunnah',
      mosqueName: 'Dar Al-Salam Centre',
      category: _Category.sisters,
      isFree: true,
      distanceMi: 7.2,
      dateTime: DateTime(now.year, now.month, now.day, 13, 0)
          .add(const Duration(days: 5)),
      attendees: 19,
      isFeatured: false,
      avatarColors: [
        Color(0xFFEC4899), Color(0xFF2DD4A0), Color(0xFFD4A847),
      ],
    ),
    _Event(
      id: '9',
      title: 'Islamic Finance Workshop',
      mosqueName: 'East London Mosque',
      category: _Category.islamicStudy,
      isFree: false,
      price: 5.00,
      distanceMi: 1.5,
      dateTime: DateTime(now.year, now.month, now.day, 14, 0)
          .add(const Duration(days: 6)),
      attendees: 40,
      isFeatured: true,
      avatarColors: [Color(0xFFD4A847), Color(0xFF2DD4A0), Color(0xFF3B82F6)],
    ),
    _Event(
      id: '10',
      title: 'Annual Charity Dinner',
      mosqueName: 'Central Mosque',
      category: _Category.community,
      isFree: false,
      price: 15.00,
      distanceMi: 1.9,
      dateTime: DateTime(now.year, now.month, now.day, 18, 30)
          .add(const Duration(days: 7)),
      attendees: 120,
      isFeatured: true,
      avatarColors: [
        Color(0xFF9B59F5), Color(0xFFEC4899), Color(0xFFD4A847),
        Color(0xFF2DD4A0),
      ],
    ),
  ];
}

final _allEvents = _buildMockEvents();

// ── Screen ────────────────────────────────────────────────────────────────

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  double _radiusMi = 2.0;
  final _myEventIds = <String>{};
  final _attendeeOverrides = <String, int>{};

  bool _anchoredToGps = true;
  bool _showAddressInput = false;
  bool _geocoding = false;
  final _addressCtrl = TextEditingController();
  String? _anchorLabel;
  String? _apiKey;

  static const _radii = [0.5, 2.0, 5.0, 10.0];
  static const _kMyEventIds = 'my_event_ids';
  static const _kUserName = 'user_name';
  static const _kUserEmail = 'user_email';

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    _loadMyEvents();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMyEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMyEventIds) ?? '[]';
    final ids = (jsonDecode(raw) as List).cast<String>();
    if (!mounted) { return; }
    setState(() {
      _myEventIds.addAll(ids);
      for (final id in ids) {
        if (!_attendeeOverrides.containsKey(id)) {
          final matches = _allEvents.where((e) => e.id == id);
          if (matches.isNotEmpty) {
            _attendeeOverrides[id] = matches.first.attendees + 1;
          }
        }
      }
    });
  }

  Future<void> _saveMyEvent(_Event event) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMyEventIds) ?? '[]';
    final ids = (jsonDecode(raw) as List).cast<String>();
    if (!ids.contains(event.id)) {
      ids.add(event.id);
      await prefs.setString(_kMyEventIds, jsonEncode(ids));
    }
  }

  Future<void> _geocodeAddress() async {
    final query = _addressCtrl.text.trim();
    if (query.isEmpty || _apiKey == null) { return; }
    setState(() => _geocoding = true);
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent('$query, UK')}&key=$_apiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) { return; }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address not found. Please try again.')),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          _anchoredToGps = false;
          _showAddressInput = false;
          _anchorLabel = query;
        });
        _addressCtrl.clear();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address not found. Please try again.')),
        );
      }
    } finally {
      if (mounted) { setState(() => _geocoding = false); }
    }
  }

  void _switchToCurrentLocation() {
    setState(() {
      _anchoredToGps = true;
      _showAddressInput = false;
      _anchorLabel = null;
    });
    _addressCtrl.clear();
  }

  Future<void> _joinEvent(_Event event) async {
    if (_myEventIds.contains(event.id)) { return; }

    if (!event.isFree) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => _PaymentPlaceholderDialog(event: event),
      );
      if (proceed != true || !mounted) { return; }
    }

    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (_) => _JoinRegistrationDialog(
        event: event,
        nameKey: _kUserName,
        emailKey: _kUserEmail,
      ),
    );
    if (result == null || !mounted) { return; }

    await _saveMyEvent(event);
    setState(() {
      _myEventIds.add(event.id);
      _attendeeOverrides[event.id] = _count(event) + 1;
    });

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _ConfirmationScreen(event: event, attendee: result),
        ),
      );
    }
  }

  List<_Event> get _filtered {
    return _allEvents.where((e) => e.distanceMi <= _radiusMi).toList()
      ..sort((a, b) {
        final d = a.distanceMi.compareTo(b.distanceMi);
        return d != 0 ? d : a.dateTime.compareTo(b.dateTime);
      });
  }

  int _count(_Event e) => _attendeeOverrides[e.id] ?? e.attendees;

  String _distLabel(double d) =>
      d < 0.1 ? '${(d * 5280).round()} ft' : '${d.toStringAsFixed(1)} mi';

  @override
  Widget build(BuildContext context) {
    final events = _filtered;
    return Scaffold(
      backgroundColor: AppTheme.background,
      // TODO: RE-ENABLE LOCK OVERLAY BEFORE MVP RELEASE
      body: Column(
        children: [
          _Header(
            radii: _radii,
            selected: _radiusMi,
            onSelect: (r) => setState(() => _radiusMi = r),
            anchoredToGps: _anchoredToGps,
            showAddressInput: _showAddressInput,
            geocoding: _geocoding,
            addressCtrl: _addressCtrl,
            anchorLabel: _anchorLabel,
            onSwitchToGps: _switchToCurrentLocation,
            onSwitchToAddress: () =>
                setState(() => _showAddressInput = true),
            onAddressSubmit: _geocodeAddress,
            onMyEvents: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    _MyEventsScreen(myEventIds: Set.of(_myEventIds)),
              ),
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? _EmptyState(
                    onExpand: () =>
                        setState(() => _radiusMi = _radii.last),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: events.length,
                    itemBuilder: (context, i) {
                      final e = events[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EventCard(
                          event: e,
                          joined: _myEventIds.contains(e.id),
                          attendeeCount: _count(e),
                          distLabel: _distLabel(e.distanceMi),
                          dateLabel: _formatEventDate(e.dateTime),
                          onJoin: () => _joinEvent(e),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
