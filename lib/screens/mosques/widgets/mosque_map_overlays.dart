part of '../mosques_screen.dart';

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
