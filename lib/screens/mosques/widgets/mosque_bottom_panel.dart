part of '../mosques_screen.dart';

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
                    : AppTheme.card,
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
                        : AppTheme.card,
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
            : AppTheme.card,
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
            color: AppTheme.card,
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
