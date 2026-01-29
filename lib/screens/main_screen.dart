import 'package:flutter/material.dart';
import 'package:focustalk_app/screens/home_screen.dart';
import 'package:focustalk_app/screens/stats_screen.dart';
import 'package:focustalk_app/screens/practice_quiz_screen.dart';
import 'package:focustalk_app/screens/settings_screen.dart';
import 'package:focustalk_app/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of pages for bottom navigation
  final List<Widget> _pages = const [
    HomeScreen(),       // Index 0
    StatsScreen(),      // Index 1
    PracticeQuizScreen(), // Index 2 (FAB action)
    SettingsScreen(),   // Index 3
    ProfileScreen(),    // Index 4
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Helper to determine icon color based on selection
  Color _getIconColor(int index) {
    return _selectedIndex == index ? Colors.deepOrange : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        elevation: 8,
        backgroundColor: Colors.deepOrange,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.edit_note,
          size: 32,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        elevation: 8,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Button (Index 0)
            IconButton(
              onPressed: () => _onItemTapped(0),
              icon: Icon(
                Icons.home_rounded,
                color: _getIconColor(0),
                size: 28,
              ),
            ),
            // Stats Button (Index 1)
            IconButton(
              onPressed: () => _onItemTapped(1),
              icon: Icon(
                Icons.bar_chart_rounded,
                color: _getIconColor(1),
                size: 28,
              ),
            ),
            // Spacer for FAB (48px width)
            const SizedBox(width: 48),
            // Settings Button (Index 3)
            IconButton(
              onPressed: () => _onItemTapped(3),
              icon: Icon(
                Icons.settings_rounded,
                color: _getIconColor(3),
                size: 28,
              ),
            ),
            // Profile Button (Index 4)
            IconButton(
              onPressed: () => _onItemTapped(4),
              icon: Icon(
                Icons.person_rounded,
                color: _getIconColor(4),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

