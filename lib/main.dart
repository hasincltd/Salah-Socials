import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'navigation/main_navigation.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'services/firestore_service.dart';
import 'services/traveler_alert_service.dart';
import 'widgets/ss_coins_widget.dart';

// Whether Firebase.initializeApp() succeeded — false until flutterfire configure runs.
bool _firebaseReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initNotifBadge();
  await initSsCoins();
  await TravelerAlertService.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseReady = true;
  } catch (_) {
    // Firebase not yet configured — run flutterfire configure to enable auth.
  }

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
      home: const _AuthGate(),
    );
  }
}

// ── Auth gate ─────────────────────────────────────────────────────────────

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _onboardingComplete;
  String? _lastSyncedUserId;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
    if (_firebaseReady) {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null && user.uid != _lastSyncedUserId) {
          _lastSyncedUserId = user.uid;
          FirestoreService.instance.syncOnLogin(user.uid);
        } else if (user == null) {
          _lastSyncedUserId = null;
        }
      });
    }
  }

  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Still loading SharedPreferences
    if (_onboardingComplete == null) return const _SplashScreen();

    // Firebase not configured — show onboarding in offline mode
    if (!_firebaseReady) return const OnboardingScreen();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        final user = snapshot.data;
        // Logged in AND previously completed onboarding → skip to home
        if (user != null && _onboardingComplete!) {
          return const MainNavigation();
        }
        // Not logged in, or logged in mid-onboarding → show onboarding flow
        // Flutter preserves OnboardingScreen state between rebuilds because the
        // widget type stays the same at the same tree position.
        return const OnboardingScreen();
      },
    );
  }
}

// ── Splash screen ─────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
