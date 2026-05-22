import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
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
            Icon(Icons.event_outlined, size: 64, color: AppTheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Events',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Mosque community events\ncoming soon',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}
