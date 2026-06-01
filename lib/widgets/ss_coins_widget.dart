import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

// ── Global balance state ──────────────────────────────────────────────────

const _kSsCoinsKey    = 'ss_coin_balance';
const _kTotalScoreKey = 'total_streak_score';

final ValueNotifier<int> ssCoinBalance = ValueNotifier<int>(0);

int _computeTotalScore(SharedPreferences prefs) {
  const names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  final dates = <String>{};
  for (final k in prefs.getKeys()) {
    if (k.startsWith('prayer_log_')) {
      final parts = k.split('_');
      if (parts.length == 4) dates.add(parts[2]);
    }
  }
  int total = 0;
  for (final dk in dates) {
    if (names.every((n) => prefs.getBool('prayer_log_${dk}_$n') == true)) {
      total++;
    }
  }
  return total;
}

Future<void> initSsCoins() async {
  final prefs = await SharedPreferences.getInstance();
  final total = _computeTotalScore(prefs);
  await prefs.setInt(_kTotalScoreKey, total);
  final balance = total * 5;
  await prefs.setInt(_kSsCoinsKey, balance);
  ssCoinBalance.value = balance;
}

// ── Widget ────────────────────────────────────────────────────────────────

class SSCoinWidget extends StatelessWidget {
  const SSCoinWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ssCoinBalance,
      builder: (context, balance, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 27,
                height: 18,
                child: CustomPaint(painter: _CoinPainter()),
              ),
              const SizedBox(width: 5),
              Text(
                '$balance',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Coin icon painter — two stacked gold circles with "SS" ────────────────

class _CoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;

    // Back coin (offset left, slightly dimmer)
    canvas.drawCircle(
      Offset(r - 3, r),
      r,
      Paint()..color = AppTheme.primary.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      Offset(r - 3, r),
      r,
      Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Front coin (offset right, full gold)
    canvas.drawCircle(
      Offset(r + 3, r),
      r,
      Paint()..color = AppTheme.primary,
    );
    // Inner highlight rim
    canvas.drawCircle(
      Offset(r + 3, r),
      r - 1,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // "SS" engraved text on front coin
    final tp = TextPainter(
      text: TextSpan(
        text: 'SS',
        style: TextStyle(
          color: AppTheme.onPrimary,
          fontSize: r * 0.72,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r + 3 - tp.width / 2, r - tp.height / 2));
  }

  @override
  bool shouldRepaint(_CoinPainter old) => false;
}
