part of '../events_screen.dart';

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
          bottom: BorderSide(color: AppTheme.card, width: 1),
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
