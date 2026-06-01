part of '../events_screen.dart';

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
                border: Border.all(color: AppTheme.card),
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
        border: Border.all(color: AppTheme.card, width: 1),
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
