import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_outlined, size: 64, color: AppTheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Settings',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'App preferences & account\ncoming soon',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}
