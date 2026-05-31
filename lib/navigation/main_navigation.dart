import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/mosques/mosques_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/community/community_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../services/traveler_alert_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    TravelerAlertService.start();
    travelAlertTabTrigger.addListener(_onTravelAlertTap);
  }

  @override
  void dispose() {
    TravelerAlertService.stop();
    travelAlertTabTrigger.removeListener(_onTravelAlertTap);
    super.dispose();
  }

  void _onTravelAlertTap() {
    // Switch to Mosques tab (index 1) when notification is tapped
    setState(() => _currentIndex = 1);
  }

  static const List<Widget> _screens = [
    HomeScreen(),
    MosquesScreen(),
    EventsScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.mosque_outlined),
      selectedIcon: Icon(Icons.mosque),
      label: 'Mosques',
    ),
    NavigationDestination(
      icon: Icon(Icons.event_outlined),
      selectedIcon: Icon(Icons.event_rounded),
      label: 'Events',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people_rounded),
      label: 'Community',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'My Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _destinations,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
