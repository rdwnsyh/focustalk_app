import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:focustalk_app/screens/home_screen.dart';
import 'package:focustalk_app/screens/permission_screen.dart';
import 'package:focustalk_app/screens/main_screen.dart';
import 'package:focustalk_app/screens/login_screen.dart';
import 'package:focustalk_app/screens/onboarding_screen.dart';
import 'package:focustalk_app/screens/splash_screen.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:focustalk_app/services/background_service.dart';
import 'package:focustalk_app/services/auth_service.dart';
import 'package:focustalk_app/screens/overlay_quiz_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma("vm:entry-point")
void overlayMain() async {
  print('═══════════════════════════════════════════════════════');
  print('🟢 OVERLAY ISOLATE: Entry point called');
  print('═══════════════════════════════════════════════════════');

  WidgetsFlutterBinding.ensureInitialized();
  print('🟢 OVERLAY ISOLATE: Flutter bindings initialized');

  // CRITICAL: Initialize database connection in THIS isolate
  // The overlay runs in a SEPARATE isolate from the main app
  // so we MUST open the database connection here
  print('🟢 OVERLAY ISOLATE: Opening database connection...');
  try {
    final db = await DatabaseHelper().database;
    print('🟢 OVERLAY ISOLATE: Database connected successfully');
    print('🟢 OVERLAY ISOLATE: Database path: ${db.path}');

    // Verify questions exist
    final count = await db.rawQuery('SELECT COUNT(*) as count FROM questions');
    final totalQuestions = count.first['count'];
    print('🟢 OVERLAY ISOLATE: Found $totalQuestions questions in database');

    if (totalQuestions == 0) {
      print('⚠️ OVERLAY ISOLATE: No questions found, seeding database...');
      await DatabaseHelper().seedDatabase();
      print('✅ OVERLAY ISOLATE: Database seeded');
    }
  } catch (e) {
    print('❌ OVERLAY ISOLATE: Database initialization failed: $e');
  }

  print('🟢 OVERLAY ISOLATE: Launching overlay UI...');
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Material(child: OverlayQuizScreen()),
    ),
  );
  print('🟢 OVERLAY ISOLATE: UI launched');
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
    return GetMaterialApp(
      title: 'FocusTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // SplashScreen handles the login check and navigation
      home: const SplashScreen(),
    );
  }
}
