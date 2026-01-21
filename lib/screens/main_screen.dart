import 'package:flutter/material.dart';
import 'package:focustalk_app/screens/home_screen.dart';
import 'package:focustalk_app/screens/apps_screen.dart';
import 'package:focustalk_app/screens/practice_quiz_screen.dart';
import 'package:focustalk_app/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of pages for bottom navigation
  final List<Widget> _pages = const [
    HomeScreen(),
    AppsScreen(),
    PracticeQuizScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        elevation: 8,
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_rounded),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Colors.blue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_rounded),
            selectedIcon: Icon(Icons.apps_rounded, color: Colors.blue),
            label: 'Apps',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_rounded),
            selectedIcon: Icon(Icons.school_rounded, color: Colors.blue),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            selectedIcon: Icon(Icons.settings_rounded, color: Colors.blue),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
