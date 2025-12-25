import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:focustalk_app/screens/permission_screen.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:focustalk_app/services/background_service.dart';
import 'package:focustalk_app/screens/overlay_quiz_screen.dart';

@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed database in overlay isolate (runs separately from main app)
  print('🎯 Overlay isolate starting - seeding database...');
  await DatabaseHelper().seedDatabase();
  print('✅ Database seeded in overlay isolate');

  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(child: OverlayQuizScreen()),
    ),
  );
}

void main() async {
  print('═══════════════════════════════════════════════════════');
  print('🚀 FOCUSTALK APP STARTING - MAIN() CALLED');
  print('═══════════════════════════════════════════════════════');

  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter bindings initialized');

  // Initialize database and seed data (apps + questions)
  print('📁 Starting database initialization...');
  await DatabaseHelper().seedDatabase();
  print('✅ Database initialized and seeded');

  print('🔧 Starting background service initialization...');
  await BackgroundServiceManager().initializeService();
  print('✅ Background service initialized');

  print('🎨 Launching Flutter app UI...');
  runApp(const FocusTalkApp());
  print('✅ runApp() called - UI should be visible now');
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
