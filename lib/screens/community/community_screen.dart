import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppTheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Community',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prayer streaks with friends\ncoming soon',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}
