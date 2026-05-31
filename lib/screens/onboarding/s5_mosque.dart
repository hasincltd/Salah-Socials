import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class S5Mosque extends StatefulWidget {
  final void Function(String? mosqueName) onNext;
  final VoidCallback onSkip;

  const S5Mosque({super.key, required this.onNext, required this.onSkip});

  @override
  State<S5Mosque> createState() => _S5MosqueState();
}

class _S5MosqueState extends State<S5Mosque> {
  final _searchCtrl = TextEditingController();
  String? _selected;
  String _query = '';

  static const List<_MockMosque> _mockMosques = [
    _MockMosque('East London Mosque', 'Whitechapel Road, London',
        ['Fajr 05:12', 'Dhuhr 13:05', 'Asr 16:30', 'Maghrib 20:18', 'Isha 21:45']),
    _MockMosque('Islamic Cultural Centre', 'Regent\'s Park, London',
        ['Fajr 05:15', 'Dhuhr 13:10', 'Asr 16:35', 'Maghrib 20:20', 'Isha 21:50']),
    _MockMosque('Finsbury Park Mosque', 'St Thomas\'s Rd, London',
        ['Fajr 05:10', 'Dhuhr 13:00', 'Asr 16:28', 'Maghrib 20:15', 'Isha 21:42']),
    _MockMosque('Birmingham Central Mosque', 'Belgrave Middleway, Birmingham',
        ['Fajr 05:08', 'Dhuhr 12:58', 'Asr 16:25', 'Maghrib 20:12', 'Isha 21:40']),
    _MockMosque('Manchester Central Mosque', 'Upper Park Rd, Manchester',
        ['Fajr 05:20', 'Dhuhr 13:08', 'Asr 16:32', 'Maghrib 20:22', 'Isha 21:48']),
  ];

  List<_MockMosque> get _filtered {
    if (_query.isEmpty) return _mockMosques;
    return _mockMosques
        .where((m) => m.name.toLowerCase().contains(_query.toLowerCase()) ||
            m.address.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
              'Your Mosque',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set your home mosque for prayer time alerts',
              style:
                  GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSubtle),
            ),
            const SizedBox(height: 20),
            // Search field
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: GoogleFonts.outfit(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search mosques by name or location',
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppTheme.textSubtle, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            // Mosque list
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text('No mosques found',
                          style: GoogleFonts.outfit(
                              color: AppTheme.textSubtle, fontSize: 14)),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final mosque = _filtered[i];
                        final isSelected = mosque.name == _selected;
                        return _MosqueTile(
                          mosque: mosque,
                          selected: isSelected,
                          onTap: () => setState(() {
                            _selected = isSelected ? null : mosque.name;
                          }),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected != null
                    ? () => widget.onNext(_selected)
                    : null,
                child: const Text('Next'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: widget.onSkip,
                child: Text('Skip for now',
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppTheme.textSubtle,
                        fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MockMosque {
  final String name;
  final String address;
  final List<String> prayerTimes;

  const _MockMosque(this.name, this.address, this.prayerTimes);
}

class _MosqueTile extends StatelessWidget {
  final _MockMosque mosque;
  final bool selected;
  final VoidCallback onTap;

  const _MosqueTile(
      {required this.mosque, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFF1F2D4A),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mosque_rounded,
                    size: 18,
                    color: selected ? AppTheme.primary : AppTheme.textSubtle),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(mosque.name,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textPrimary)),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: AppTheme.primary),
              ],
            ),
            const SizedBox(height: 3),
            Text(mosque.address,
                style: GoogleFonts.outfit(
                    fontSize: 12, color: AppTheme.textSubtle)),
            if (selected) ...[
              const SizedBox(height: 10),
              // Prayer times preview
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: mosque.prayerTimes
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.card,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(t,
                              style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
