import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:focustalk_app/screens/permission_screen.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:focustalk_app/screens/overlay_quiz_screen.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(child: OverlayQuizScreen()),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database and seed dummy data
  final dbHelper = DatabaseHelper();
  await dbHelper.seedDummyData();

  runApp(const FocusTalkApp());
}

class FocusTalkApp extends StatelessWidget {
  const FocusTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PermissionScreen(),
    );
  }
}
