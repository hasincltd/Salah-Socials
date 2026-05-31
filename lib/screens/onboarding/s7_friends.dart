import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class S7Friends extends StatefulWidget {
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  const S7Friends({super.key, required this.onFinish, required this.onSkip});

  @override
  State<S7Friends> createState() => _S7FriendsState();
}

class _S7FriendsState extends State<S7Friends> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _showQr = false;

  static const _mockUsers = [
    ('adam_k', 'Adam K.', 11),
    ('ibrahim_s', 'Ibrahim S.', 9),
    ('omar_r', 'Omar R.', 7),
    ('yusuf_m', 'Yusuf M.', 5),
  ];

  final Set<String> _sent = {};

  List<(String, String, int)> get _results {
    if (_query.isEmpty) return [];
    return _mockUsers
        .where((u) => u.$1.contains(_query.toLowerCase()) ||
            u.$2.toLowerCase().contains(_query.toLowerCase()))
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
              'Find Friends',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Connect with fellow believers',
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
                hintText: 'Search by username',
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppTheme.textSubtle, size: 20),
              ),
            ),
            const SizedBox(height: 16),
            // Search results
            if (_results.isNotEmpty)
              Column(
                children: _results
                    .map((u) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _UserTile(
                            username: u.$1,
                            displayName: u.$2,
                            streak: u.$3,
                            requestSent: _sent.contains(u.$1),
                            onRequest: () => setState(() {
                              if (_sent.contains(u.$1)) {
                                _sent.remove(u.$1);
                              } else {
                                _sent.add(u.$1);
                              }
                            }),
                          ),
                        ))
                    .toList(),
              )
            else if (_query.isEmpty) ...[
              // QR share section
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Or share your QR code',
                      style: GoogleFonts.outfit(
                          fontSize: 14, color: AppTheme.textSubtle),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => setState(() => _showQr = !_showQr),
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: const Color(0xFF1F2D4A), width: 1.5),
                        ),
                        child: _showQr
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: CustomPaint(
                                    painter: _QrPlaceholderPainter()),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.qr_code_rounded,
                                      size: 56, color: AppTheme.primary),
                                  const SizedBox(height: 8),
                                  Text('Show QR Code',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppTheme.textSubtle)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            const ClipboardData(text: 'salahsocials.app/u/hasin'));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Profile link copied',
                              style: GoogleFonts.outfit(
                                  color: AppTheme.textPrimary)),
                          backgroundColor: AppTheme.surface,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ));
                      },
                      icon: const Icon(Icons.share_rounded,
                          size: 16, color: AppTheme.primary),
                      label: Text('Share profile link',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: AppTheme.primary)),
                    ),
                  ],
                ),
              ),
            ] else
              Center(
                child: Text('No users found for "$_query"',
                    style: GoogleFonts.outfit(
                        fontSize: 13, color: AppTheme.textSubtle)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onFinish,
                child: Text(_sent.isNotEmpty
                    ? 'Done  ·  ${_sent.length} request${_sent.length == 1 ? '' : 's'} sent'
                    : 'Finish'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: widget.onSkip,
                child: Text('Skip & find friends later',
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

class _UserTile extends StatelessWidget {
  final String username;
  final String displayName;
  final int streak;
  final bool requestSent;
  final VoidCallback onRequest;

  const _UserTile({
    required this.username,
    required this.displayName,
    required this.streak,
    required this.requestSent,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2D4A), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.15),
              border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Center(
              child: Text(displayName[0].toUpperCase(),
                  style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                Text('@$username  ·  🔥 $streak',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: AppTheme.textSubtle)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRequest,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: requestSent
                    ? AppTheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: requestSent
                      ? AppTheme.primary
                      : AppTheme.textSubtle.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                requestSent ? 'Sent' : '+ Add',
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: requestSent
                        ? AppTheme.primary
                        : AppTheme.textSubtle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple dot-matrix QR placeholder
class _QrPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.fill;
    const grid = 7;
    final cell = size.width / grid;

    // Simulated QR finder patterns (corners) + random data modules
    final filled = {
      '0,0', '1,0', '2,0', '3,0', '4,0', '5,0', '6,0',
      '0,1', '6,1', '0,2', '2,2', '3,2', '4,2', '6,2',
      '0,3', '6,3', '0,4', '2,4', '3,4', '4,4', '6,4',
      '0,5', '6,5', '0,6', '1,6', '2,6', '3,6', '4,6', '5,6', '6,6',
      '2,1', '3,1', '4,1', '2,3', '4,3', '2,5', '3,5', '4,5',
      '1,2', '5,2', '1,3', '5,3', '1,4', '5,4',
    };

    for (int r = 0; r < grid; r++) {
      for (int c = 0; c < grid; c++) {
        if (filled.contains('$c,$r')) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                  c * cell + 1, r * cell + 1, cell - 2, cell - 2),
              const Radius.circular(1.5),
            ),
            p,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPlaceholderPainter old) => false;
}
