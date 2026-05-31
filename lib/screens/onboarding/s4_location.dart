import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class S4Location extends StatefulWidget {
  final void Function({
    double? latitude,
    double? longitude,
    String? postcode,
  }) onNext;

  const S4Location({super.key, required this.onNext});

  @override
  State<S4Location> createState() => _S4LocationState();
}

class _S4LocationState extends State<S4Location> {
  bool _loading = false;
  bool _showManual = false;
  final _postcodeCtrl = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _postcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _errorMessage =
              'Location permission denied. Use "Set Manually" instead.';
          _loading = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      widget.onNext(latitude: pos.latitude, longitude: pos.longitude);
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not get location. Try setting it manually.';
        _loading = false;
      });
    }
  }

  void _submitManual() {
    final postcode = _postcodeCtrl.text.trim();
    if (postcode.isEmpty) {
      setState(() => _errorMessage = 'Please enter a postcode.');
      return;
    }
    widget.onNext(postcode: postcode);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Your Location',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'For accurate prayer times and nearby mosques',
              style:
                  GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSubtle),
            ),
            const Spacer(flex: 2),
            // Location icon
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withValues(alpha: 0.10),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.25), width: 1.5),
                ),
                child: const Icon(Icons.location_on_rounded,
                    size: 52, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'We use your location to calculate prayer\ntimes and show nearby mosques',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textSubtle,
                  height: 1.6,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.35), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: AppTheme.error)),
                    ),
                  ],
                ),
              ),
            ],
            if (_showManual) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _postcodeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Enter postcode (e.g. SW1A 2AA)',
                  prefixIcon: Icon(Icons.pin_drop_outlined,
                      color: AppTheme.textSubtle, size: 20),
                ),
              ),
            ],
            const Spacer(flex: 3),
            // Buttons
            if (!_showManual) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _requestLocation,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.onPrimary),
                        )
                      : const Icon(Icons.my_location_rounded, size: 18),
                  label:
                      Text(_loading ? 'Detecting...' : 'Allow Location Access'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _showManual = true;
                    _errorMessage = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1F2D4A), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Set Manually',
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary)),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitManual,
                  child: const Text('Confirm Location'),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: () => setState(() {
                    _showManual = false;
                    _errorMessage = null;
                  }),
                  child: Text('Back',
                      style: GoogleFonts.outfit(
                          fontSize: 13, color: AppTheme.textSubtle)),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
