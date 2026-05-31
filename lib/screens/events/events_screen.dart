import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../notifications/notifications_screen.dart';

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
      body: Stack(
        children: [
          // Content at 25% opacity.
          // AbsorbPointer wraps interactive widgets so taps are blocked, but
          // the ListView itself is unwrapped so scroll drag events still work.
          Opacity(
            opacity: 0.25,
            child: Column(
              children: [
                AbsorbPointer(
                  child: _Header(
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
                ),
                Expanded(
                  child: events.isEmpty
                      ? AbsorbPointer(
                          child: _EmptyState(
                            onExpand: () =>
                                setState(() => _radiusMi = _radii.last),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: events.length,
                          itemBuilder: (context, i) {
                            final e = events[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AbsorbPointer(
                                child: _EventCard(
                                  event: e,
                                  joined: _myEventIds.contains(e.id),
                                  attendeeCount: _count(e),
                                  distLabel: _distLabel(e.distanceMi),
                                  dateLabel: _formatEventDate(e.dateTime),
                                  onJoin: () => _joinEvent(e),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Lock overlay — IgnorePointer so it doesn't block scroll events.
          IgnorePointer(
            child: Align(
              alignment: const Alignment(0, 0.15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 100,
                    color: AppTheme.textPrimary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Coming Soon',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Events Launching Soon',
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
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final List<double> radii;
  final double selected;
  final ValueChanged<double> onSelect;
  final bool anchoredToGps;
  final bool showAddressInput;
  final bool geocoding;
  final TextEditingController addressCtrl;
  final String? anchorLabel;
  final VoidCallback onSwitchToGps;
  final VoidCallback onSwitchToAddress;
  final VoidCallback onAddressSubmit;
  final VoidCallback onMyEvents;

  const _Header({
    required this.radii,
    required this.selected,
    required this.onSelect,
    required this.anchoredToGps,
    required this.showAddressInput,
    required this.geocoding,
    required this.addressCtrl,
    required this.anchorLabel,
    required this.onSwitchToGps,
    required this.onSwitchToAddress,
    required this.onAddressSubmit,
    required this.onMyEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: Color(0xFF1A2440), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nearby Events',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onMyEvents,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1F2D4A)),
                      ),
                      child: Icon(
                        Icons.bookmark_rounded,
                        size: 18,
                        color: AppTheme.textSubtle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const BellIconButton(),
                  const SizedBox(width: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1F2D4A)),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppTheme.textSubtle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _EventsLocationBar(
                anchoredToGps: anchoredToGps,
                anchorLabel: anchorLabel,
                onSwitchToGps: onSwitchToGps,
                onSwitchToAddress: onSwitchToAddress,
              ),
              if (showAddressInput) ...[
                const SizedBox(height: 10),
                _EventsAddressInput(
                  controller: addressCtrl,
                  geocoding: geocoding,
                  onSubmit: onAddressSubmit,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Radius:',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.textSubtle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ...radii.map((r) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _Pill(
                      label: r < 1 ? '${r}mi' : '${r.toInt()}mi',
                      selected: r == selected,
                      onTap: () => onSelect(r),
                    ),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Events location bar ───────────────────────────────────────────────────

class _EventsLocationBar extends StatelessWidget {
  final bool anchoredToGps;
  final String? anchorLabel;
  final VoidCallback onSwitchToGps;
  final VoidCallback onSwitchToAddress;

  const _EventsLocationBar({
    required this.anchoredToGps,
    required this.anchorLabel,
    required this.onSwitchToGps,
    required this.onSwitchToAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: anchoredToGps ? null : onSwitchToGps,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: anchoredToGps ? AppTheme.primary : AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: anchoredToGps
                    ? AppTheme.primary
                    : const Color(0xFF1F2D4A),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.my_location_rounded,
                  size: 13,
                  color: anchoredToGps
                      ? AppTheme.onPrimary
                      : AppTheme.textSubtle,
                ),
                const SizedBox(width: 5),
                Text(
                  'Current Location',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: anchoredToGps
                        ? AppTheme.onPrimary
                        : AppTheme.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: anchoredToGps ? onSwitchToAddress : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: anchoredToGps ? AppTheme.surface : AppTheme.primary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: anchoredToGps
                    ? const Color(0xFF1F2D4A)
                    : AppTheme.primary,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 13,
                  color: anchoredToGps
                      ? AppTheme.textSubtle
                      : AppTheme.onPrimary,
                ),
                const SizedBox(width: 5),
                Text(
                  anchorLabel ?? 'Choose Address',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: anchoredToGps
                        ? AppTheme.textSubtle
                        : AppTheme.onPrimary,
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

// ── Events address input ──────────────────────────────────────────────────

class _EventsAddressInput extends StatelessWidget {
  final TextEditingController controller;
  final bool geocoding;
  final VoidCallback onSubmit;

  const _EventsAddressInput({
    required this.controller,
    required this.geocoding,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: GoogleFonts.outfit(
                fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter postcode or address',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1.5),
              ),
              hintStyle: GoogleFonts.outfit(
                  fontSize: 14, color: AppTheme.textSubtle),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSubmit(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: geocoding ? null : onSubmit,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: geocoding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.search_rounded,
                    size: 18, color: AppTheme.onPrimary),
          ),
        ),
      ],
    );
  }
}

// ── Radius pill ───────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFF1F2D4A),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.onPrimary : AppTheme.textSubtle,
          ),
        ),
      ),
    );
  }
}

// ── Event card ────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final _Event event;
  final bool joined;
  final int attendeeCount;
  final String distLabel;
  final String dateLabel;
  final VoidCallback onJoin;

  const _EventCard({
    required this.event,
    required this.joined,
    required this.attendeeCount,
    required this.distLabel,
    required this.dateLabel,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2440), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gold spotlight strip for featured events
            if (event.isFeatured)
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFD4A847),
                      Color(0xFFF0C96A),
                      Color(0xFFD4A847),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: category + badges + distance
                  Row(
                    children: [
                      _CategoryTag(category: event.category),
                      const SizedBox(width: 7),
                      if (event.isFree)
                        const _FreeBadge()
                      else if (event.price != null)
                        _PriceBadge(price: event.price!),
                      if (event.isFeatured) ...[
                        const SizedBox(width: 7),
                        _SpotlightBadge(),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.place_outlined,
                        size: 12,
                        color: AppTheme.textSubtle,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        distLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSubtle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    event.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Mosque name
                  Row(
                    children: [
                      Icon(
                        Icons.mosque_outlined,
                        size: 13,
                        color: AppTheme.primary.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        event.mosqueName,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSubtle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Date & time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: AppTheme.textSubtle.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        dateLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSubtle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Bottom row: avatar stack + count + join
                  Row(
                    children: [
                      _AvatarStack(colors: event.avatarColors),
                      const SizedBox(width: 8),
                      Text(
                        '$attendeeCount attending',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppTheme.textSubtle,
                        ),
                      ),
                      const Spacer(),
                      _JoinButton(joined: joined, onTap: onJoin),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category tag ──────────────────────────────────────────────────────────

class _CategoryTag extends StatelessWidget {
  final _Category category;
  const _CategoryTag({required this.category});

  @override
  Widget build(BuildContext context) {
    final col = category.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        category.label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: col,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Free badge ────────────────────────────────────────────────────────────

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    const col = Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        'FREE',
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: col,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ── Price badge ───────────────────────────────────────────────────────────

class _PriceBadge extends StatelessWidget {
  final double price;
  const _PriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    const col = AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: col.withValues(alpha: 0.28), width: 1),
      ),
      child: Text(
        '£${price.toStringAsFixed(2)}',
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: col,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ── Spotlight badge ───────────────────────────────────────────────────────

class _SpotlightBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 10, color: AppTheme.primary),
          const SizedBox(width: 3),
          Text(
            'Spotlight',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Avatar stack ──────────────────────────────────────────────────────────

class _AvatarStack extends StatelessWidget {
  final List<Color> colors;
  const _AvatarStack({required this.colors});

  @override
  Widget build(BuildContext context) {
    final count = colors.length.clamp(0, 4);
    final width = 22.0 + (count - 1) * 16.0;
    return SizedBox(
      width: width.clamp(22.0, double.infinity),
      height: 24,
      child: Stack(
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: i * 16.0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i],
                  border: Border.all(color: AppTheme.surface, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Join button ───────────────────────────────────────────────────────────

class _JoinButton extends StatelessWidget {
  final bool joined;
  final VoidCallback onTap;

  const _JoinButton({required this.joined, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF22C55E);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: joined
              ? green.withValues(alpha: 0.13)
              : AppTheme.primary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: joined
                ? green.withValues(alpha: 0.45)
                : AppTheme.primary,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: joined
              ? [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: green),
                  const SizedBox(width: 5),
                  Text(
                    'Joined',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: green,
                    ),
                  ),
                ]
              : [
                  Text(
                    'Join',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onPrimary,
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onExpand;
  const _EmptyState({required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surface,
              border: Border.all(color: const Color(0xFF1A2440), width: 1.5),
            ),
            child: Icon(
              Icons.event_outlined,
              size: 34,
              color: AppTheme.primary.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No events nearby',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try expanding your radius',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSubtle,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onExpand,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Text(
                'Expand to 10 mi',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Join registration dialog ──────────────────────────────────────────────

class _JoinRegistrationDialog extends StatefulWidget {
  final _Event event;
  final String nameKey;
  final String emailKey;

  const _JoinRegistrationDialog({
    required this.event,
    required this.nameKey,
    required this.emailKey,
  });

  @override
  State<_JoinRegistrationDialog> createState() =>
      _JoinRegistrationDialogState();
}

class _JoinRegistrationDialogState extends State<_JoinRegistrationDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) { return; }
    setState(() {
      _nameCtrl.text = prefs.getString(widget.nameKey) ?? '';
      _emailCtrl.text = prefs.getString(widget.emailKey) ?? '';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Register for Event',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.event.title,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppTheme.textSubtle),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Your name',
                prefixIcon: Icon(Icons.person_outline_rounded,
                    size: 18, color: AppTheme.textSubtle),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'your@email.com',
                prefixIcon: Icon(Icons.email_outlined,
                    size: 18, color: AppTheme.textSubtle),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1F2D4A)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSubtle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, {
                      'name': _nameCtrl.text.trim(),
                      'email': _emailCtrl.text.trim(),
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment placeholder dialog ────────────────────────────────────────────

class _PaymentPlaceholderDialog extends StatelessWidget {
  final _Event event;
  const _PaymentPlaceholderDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    final priceStr = event.price != null
        ? '£${event.price!.toStringAsFixed(2)}'
        : 'Paid';
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.payment_rounded,
                  size: 28, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Required',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${event.title}\n$priceStr',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textSubtle,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Payment processing coming in Phase 2.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.textSubtle,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1F2D4A)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSubtle,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Continue',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Confirmation screen ───────────────────────────────────────────────────

class _ConfirmationScreen extends StatelessWidget {
  final _Event event;
  final Map<String, String> attendee;

  const _ConfirmationScreen({
    required this.event,
    required this.attendee,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      'event_id': event.id,
      'event': event.title,
      'mosque': event.mosqueName,
      'date': event.dateTime.toIso8601String(),
      'name': attendee['name'] ?? '',
      'email': attendee['email'] ?? '',
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Confirmed',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: Color(0xFF22C55E),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "You're registered!",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              event.mosqueName,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppTheme.textSubtle),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _formatEventDate(event.dateTime),
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppTheme.textSubtle),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A2440)),
              ),
              child: Column(
                children: [
                  Text(
                    'Your QR Code',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 180,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Show this at the entrance',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.textSubtle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Done',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Events screen ──────────────────────────────────────────────────────

class _MyEventsScreen extends StatelessWidget {
  final Set<String> myEventIds;
  const _MyEventsScreen({required this.myEventIds});

  @override
  Widget build(BuildContext context) {
    final joined = _allEvents
        .where((e) => myEventIds.contains(e.id))
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Events',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: joined.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 64,
                    color: AppTheme.textSubtle.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events joined yet',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSubtle,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: joined.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _MyEventQrCard(
                    event: joined[i],
                    dateLabel: _formatEventDate(joined[i].dateTime),
                  ),
                );
              },
            ),
    );
  }
}

// ── My Event QR card ──────────────────────────────────────────────────────

class _MyEventQrCard extends StatelessWidget {
  final _Event event;
  final String dateLabel;

  const _MyEventQrCard({required this.event, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      'event_id': event.id,
      'event': event.title,
      'mosque': event.mosqueName,
      'date': event.dateTime.toIso8601String(),
    });

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2440), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CategoryTag(category: event.category),
                const SizedBox(width: 7),
                if (event.isFree)
                  const _FreeBadge()
                else if (event.price != null)
                  _PriceBadge(price: event.price!),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              event.title,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.mosque_outlined,
                    size: 13,
                    color: AppTheme.primary.withValues(alpha: 0.75)),
                const SizedBox(width: 5),
                Text(
                  event.mosqueName,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textSubtle,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 13,
                    color: AppTheme.textSubtle.withValues(alpha: 0.6)),
                const SizedBox(width: 5),
                Text(
                  dateLabel,
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppTheme.textSubtle),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 160,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Show this at the entrance',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppTheme.textSubtle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
