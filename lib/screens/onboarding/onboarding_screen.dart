import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../navigation/main_navigation.dart';
import '../../theme/app_theme.dart';
import 's1_welcome.dart';
import 's2_auth.dart';
import 's3_profile.dart';
import 's4_location.dart';
import 's5_mosque.dart';
import 's6_notifications.dart';
import 's7_friends.dart';

// ── Onboarding screen ─────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Signals Screen 2 to open in sign-in mode when user taps "I have an account"
  final _signInModeNotifier = ValueNotifier<bool>(false);

  // Collected data
  String _username = '';
  String _displayName = '';
  double? _latitude;
  double? _longitude;
  String? _postcode;

  static const int _totalPages = 7;

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToSignIn() {
    _signInModeNotifier.value = true;
    _next();
  }

  void _goToGetStarted() {
    _signInModeNotifier.value = false;
    _next();
  }

  // Called by Screen 2 after successful auth
  void _onAuthSuccess(bool isNewUser) {
    if (!isNewUser) {
      // Returning user — skip profile setup and go straight to app
      _completeOnboarding(skipWelcome: false);
    } else {
      // New user — continue to profile setup
      _next();
    }
  }

  void _onProfileNext(String username, String displayName) {
    _username = username;
    _displayName = displayName;
    _next();
  }

  void _onLocationNext({double? latitude, double? longitude, String? postcode}) {
    _latitude = latitude;
    _longitude = longitude;
    _postcode = postcode;
    _next();
  }

  void _onMosqueNext(String? mosqueName) {
    _next();
  }

  Future<void> _completeOnboarding({bool skipWelcome = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (_username.isNotEmpty) {
      await prefs.setString('settings_username', _username);
    }
    if (_displayName.isNotEmpty) {
      await prefs.setString('settings_display_name', _displayName);
    }
    if (_postcode != null && _postcode!.isNotEmpty) {
      await prefs.setString('home_postcode', _postcode!);
    }
    if (_latitude != null) {
      await prefs.setDouble('home_latitude', _latitude!);
    }
    if (_longitude != null) {
      await prefs.setDouble('home_longitude', _longitude!);
    }
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;

    final name = _displayName.isNotEmpty ? _displayName : 'there';
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, anim, anim2) =>
            _WelcomeOverlay(displayName: name, skipAnimation: skipWelcome),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pageController.dispose();
    _signInModeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ── Progress indicator ────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: _OBProgress(current: _page, total: _totalPages),
            ),
          ),
          const SizedBox(height: 12),
          // ── Page content ──────────────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                // Screen 1 — Welcome
                S1Welcome(
                  onGetStarted: _goToGetStarted,
                  onSignIn: _goToSignIn,
                ),
                // Screen 2 — Auth
                S2Auth(
                  initialSignIn: false,
                  signInModeNotifier: _signInModeNotifier,
                  onAuthSuccess: _onAuthSuccess,
                ),
                // Screen 3 — Profile
                S3Profile(onNext: _onProfileNext),
                // Screen 4 — Location
                S4Location(onNext: _onLocationNext),
                // Screen 5 — Mosque
                S5Mosque(
                  onNext: _onMosqueNext,
                  onSkip: _next,
                ),
                // Screen 6 — Notifications
                S6Notifications(
                  onAllow: _next,
                  onSkip: _next,
                ),
                // Screen 7 — Friends
                S7Friends(
                  onFinish: () => _completeOnboarding(),
                  onSkip: () => _completeOnboarding(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress indicator ────────────────────────────────────────────────────

class _OBProgress extends StatelessWidget {
  final int current;
  final int total;

  const _OBProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step label
        Text(
          'Step ${current + 1} of $total',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSubtle,
          ),
        ),
        const SizedBox(height: 8),
        // Progress bar
        Row(
          children: List.generate(total, (i) {
            final isCompleted = i < current;
            final isCurrent = i == current;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 3,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppTheme.primary
                        : const Color(0xFF1F2D4A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Welcome overlay screen ────────────────────────────────────────────────

class _WelcomeOverlay extends StatefulWidget {
  final String displayName;
  final bool skipAnimation;

  const _WelcomeOverlay(
      {required this.displayName, this.skipAnimation = false});

  @override
  State<_WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends State<_WelcomeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _showingMain = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    if (widget.skipAnimation) {
      _navigate();
    } else {
      _ctrl.forward();
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (!mounted) return;
        _ctrl.reverse().then((_) {
          if (mounted) _navigate();
        });
      });
    }
  }

  void _navigate() {
    setState(() => _showingMain = true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showingMain) return const MainNavigation();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Home screen background (faint) — replaced by actual MainNavigation
          // after animation completes
          Container(color: AppTheme.background),
          // Welcome overlay
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Moon glow
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppTheme.primary.withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🌙',
                              style: TextStyle(fontSize: 44)),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Welcome to\nSalah Socials',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.displayName,
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'May your prayers be accepted\nand your streak never broken.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppTheme.textSubtle,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
