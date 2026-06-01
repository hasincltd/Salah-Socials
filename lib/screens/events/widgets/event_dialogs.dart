part of '../events_screen.dart';

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
