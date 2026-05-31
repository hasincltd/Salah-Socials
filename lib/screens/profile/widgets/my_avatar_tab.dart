part of '../profile_screen.dart';

// ── Full-body avatar character painter ───────────────────────────────────

class _FullBodyAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final skin  = Paint()..color = const Color(0xFFE8B89A);
    final hair  = Paint()..color = const Color(0xFF3D2314);
    final shirt = Paint()..color = AppTheme.accent;
    final pants = Paint()..color = const Color(0xFF1A2440);
    final shoes = Paint()..color = AppTheme.primary;
    final eye   = Paint()..color = const Color(0xFF2A1A0A);
    final belt  = Paint()..color = AppTheme.primary;

    final headCY  = size.height * 0.13;
    final headR   = size.width  * 0.16;
    final neckTop = headCY + headR - 2;
    final neckBot = neckTop + size.height * 0.05;
    final bodyTop = neckBot;
    final bodyBot = size.height * 0.60;
    final legsBot = size.height * 0.88;
    final shoesBot = size.height * 0.97;
    final legW    = size.width * 0.16;
    final armW    = size.width * 0.095;

    // ── Legs ─────────────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - legW * 1.25, bodyBot - 4, cx - 2, legsBot),
        const Radius.circular(6)),
      pants,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + 2, bodyBot - 4, cx + legW * 1.25, legsBot),
        const Radius.circular(6)),
      pants,
    );

    // ── Shoes ─────────────────────────────────────────────────────────────
    canvas.drawOval(
        Rect.fromLTRB(cx - legW * 1.6, legsBot - 6, cx + 4, shoesBot), shoes);
    canvas.drawOval(
        Rect.fromLTRB(cx - 4, legsBot - 6, cx + legW * 1.6, shoesBot), shoes);

    // ── Arms ──────────────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - size.width * 0.37, bodyTop + 4,
            cx - size.width * 0.26, bodyBot - 12),
        const Radius.circular(8)),
      shirt,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + size.width * 0.26, bodyTop + 4,
            cx + size.width * 0.37, bodyBot - 12),
        const Radius.circular(8)),
      shirt,
    );
    // Hands
    canvas.drawCircle(
        Offset(cx - size.width * 0.315, bodyBot - 9), armW * 0.72, skin);
    canvas.drawCircle(
        Offset(cx + size.width * 0.315, bodyBot - 9), armW * 0.72, skin);

    // ── Torso ─────────────────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - size.width * 0.255, bodyTop,
            cx + size.width * 0.255, bodyBot),
        const Radius.circular(10)),
      shirt,
    );

    // Belt
    canvas.drawRect(
      Rect.fromLTRB(cx - size.width * 0.255, bodyBot - 9,
          cx + size.width * 0.255, bodyBot - 2),
      belt,
    );

    // ── Neck ──────────────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTRB(cx - size.width * 0.07, neckTop,
          cx + size.width * 0.07, neckBot),
      skin,
    );

    // ── Head ──────────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx, headCY), headR, skin);

    // Hair top
    final hairPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(cx, headCY), radius: headR * 1.02),
        math.pi, math.pi,
      )
      ..close();
    canvas.drawPath(hairPath, hair);

    // Sideburns
    canvas.drawRect(
        Rect.fromLTRB(cx - headR, headCY - 3, cx - headR + 5, headCY + 8),
        hair);
    canvas.drawRect(
        Rect.fromLTRB(cx + headR - 5, headCY - 3, cx + headR, headCY + 8),
        hair);

    // ── Eyes ──────────────────────────────────────────────────────────────
    canvas.drawCircle(Offset(cx - headR * 0.33, headCY + 2), headR * 0.11, eye);
    canvas.drawCircle(Offset(cx + headR * 0.33, headCY + 2), headR * 0.11, eye);

    // Catchlights
    final cl = Paint()..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawCircle(Offset(cx - headR * 0.29, headCY + 0.5), headR * 0.04, cl);
    canvas.drawCircle(Offset(cx + headR * 0.37, headCY + 0.5), headR * 0.04, cl);

    // Eyebrows
    final brow = Paint()
      ..color = const Color(0xFF3D2314)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(cx - headR * 0.48, headCY - headR * 0.22),
        Offset(cx - headR * 0.18, headCY - headR * 0.17),
        brow);
    canvas.drawLine(
        Offset(cx + headR * 0.18, headCY - headR * 0.17),
        Offset(cx + headR * 0.48, headCY - headR * 0.22),
        brow);

    // Smile
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, headCY + headR * 0.26),
          width: headR * 0.72,
          height: headR * 0.36),
      0, math.pi, false,
      Paint()
        ..color = const Color(0xFF8B4513)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FullBodyAvatarPainter old) => false;
}

// ── My Avatar tab ─────────────────────────────────────────────────────────

class _MyAvatarTab extends StatefulWidget {
  const _MyAvatarTab();
  @override
  State<_MyAvatarTab> createState() => _MyAvatarTabState();
}

class _MyAvatarTabState extends State<_MyAvatarTab> {
  int _catIndex = 0;

  static const List<String> _cats = [
    'My Avatar', 'Appearance', 'Hairstyles', 'Outfit',
    'Shoes', 'Accessories', 'Seasonal',
  ];

  static const List<List<String>> _itemNames = [
    ['Default', 'Athletic', 'Scholar', 'Traveller', 'Warrior', 'Elegant'],
    ['Light', 'Medium', 'Tan', 'Brown', 'Deep', 'Custom'],
    ['Short', 'Curly', 'Afro', 'Waves', 'Long', 'Braids'],
    ['Thoub', 'Casual', 'Formal', 'Sports', 'Abaya', 'Kimono'],
    ['Sandals', 'Sneakers', 'Formal', 'Boots', 'Slip-on', 'Bare'],
    ['Glasses', 'Keffiyeh', 'Cap', 'Backpack', 'Watch', 'Ring'],
    ['Ramadan', 'Eid', 'Hajj', 'Winter', 'Summer', 'Exclusive'],
  ];

  static const List<List<IconData>> _itemIcons = [
    [Icons.person_rounded, Icons.sports_rounded, Icons.menu_book_rounded,
     Icons.flight_rounded, Icons.shield_rounded, Icons.auto_awesome_rounded],
    [Icons.face_rounded, Icons.face_rounded, Icons.face_rounded,
     Icons.face_rounded, Icons.face_rounded, Icons.palette_rounded],
    [Icons.content_cut_rounded, Icons.waves_rounded, Icons.circle_rounded,
     Icons.water_drop_rounded, Icons.blur_on_rounded, Icons.auto_awesome_rounded],
    [Icons.checkroom_rounded, Icons.style_rounded, Icons.business_center_rounded,
     Icons.sports_rounded, Icons.shopping_bag_rounded, Icons.star_rounded],
    [Icons.directions_walk_rounded, Icons.sports_rounded, Icons.workspace_premium_rounded,
     Icons.hiking_rounded, Icons.nature_rounded, Icons.spa_rounded],
    [Icons.visibility_rounded, Icons.account_balance_wallet_rounded, Icons.sports_basketball_rounded,
     Icons.school_rounded, Icons.watch_rounded, Icons.diamond_rounded],
    [Icons.nightlight_round, Icons.celebration_rounded, Icons.mosque_rounded,
     Icons.ac_unit_rounded, Icons.wb_sunny_rounded, Icons.star_rounded],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Full-body avatar character
        SizedBox(
          height: 158,
          child: Center(
            child: SizedBox(
              width: 110,
              height: 158,
              child: CustomPaint(painter: _FullBodyAvatarPainter()),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Horizontal category scroll bar
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _cats.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = i == _catIndex;
              return GestureDetector(
                onTap: () => setState(() => _catIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel
                        ? AppTheme.primary.withValues(alpha: 0.12)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel ? AppTheme.primary : const Color(0xFF1F2D4A),
                      width: 1,
                    ),
                  ),
                  child: Text(_cats[i],
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.textSubtle)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Locked items grid
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: 6,
            itemBuilder: (_, i) => _LockedAvatarItem(
              icon: _itemIcons[_catIndex][i],
              name: _itemNames[_catIndex][i],
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedAvatarItem extends StatelessWidget {
  final IconData icon;
  final String name;
  const _LockedAvatarItem({required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.25,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1F2D4A), width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 28, color: AppTheme.textSubtle),
                  const SizedBox(height: 5),
                  Text(name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSubtle)),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monetization_on_rounded,
                          size: 9, color: AppTheme.primary),
                      const SizedBox(width: 2),
                      Text('SS Coins',
                          style: GoogleFonts.outfit(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6, right: 6,
              child: Icon(Icons.lock_rounded, size: 12, color: AppTheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
