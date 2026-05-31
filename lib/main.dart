import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'navigation/main_navigation.dart';
import 'screens/notifications/notifications_screen.dart';
import 'widgets/ss_coins_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initNotifBadge();
  await initSsCoins();
  runApp(const SalahSocialsApp());
}

class SalahSocialsApp extends StatelessWidget {
  const SalahSocialsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salah Socials',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const MainNavigation(),
    );
  }
}
