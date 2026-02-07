import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:focustalk_app/screens/home_screen.dart';
import 'package:focustalk_app/screens/permission_screen.dart';
import 'package:focustalk_app/screens/main_screen.dart';
import 'package:focustalk_app/screens/login_screen.dart';
import 'package:focustalk_app/screens/onboarding_screen.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:focustalk_app/services/background_service.dart';
import 'package:focustalk_app/services/auth_service.dart';
import 'package:focustalk_app/screens/overlay_quiz_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<Map<String, bool>> checkStartupFlow() async {
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  final isLoggedIn = await AuthService().isLoggedIn();

  print('📋 Startup Flow Check:');
  print('   - Seen Onboarding: $seenOnboarding');
  print('   - Is Logged In: $isLoggedIn');

  return {'seenOnboarding': seenOnboarding, 'isLoggedIn': isLoggedIn};
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

  // Check startup flow
  final startupFlow = await checkStartupFlow();

  print('🎨 Launching Flutter app UI...');
  runApp(FocusTalkApp(startupFlow: startupFlow));
  print('✅ runApp() called - UI should be visible now');
}

class FocusTalkApp extends StatefulWidget {
  final Map<String, bool> startupFlow;

  const FocusTalkApp({super.key, required this.startupFlow});

  @override
  State<FocusTalkApp> createState() => _FocusTalkAppState();
}

class _FocusTalkAppState extends State<FocusTalkApp> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _seenOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    print('🔍 Initializing app state...');

    try {
      // Use the startup flow data passed from main()
      _seenOnboarding = widget.startupFlow['seenOnboarding'] ?? false;
      _isLoggedIn = widget.startupFlow['isLoggedIn'] ?? false;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (_isLoggedIn) {
        final user = await _authService.getUser();
        print('✅ User is logged in: ${user?['email']}');
      } else {
        print('❌ User is not logged in');
      }
    } catch (e) {
      print('❌ Error initializing app: $e');
      if (mounted) {
        setState(() {
          _seenOnboarding = false;
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show splash screen while checking auth
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade600, Colors.blue.shade400],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology_rounded, size: 80, color: Colors.white),
                  SizedBox(height: 24),
                  Text(
                    'FocusTalk',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 32),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GetMaterialApp(
      title: 'FocusTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _determineHomeScreen(),
    );
  }

  Widget _determineHomeScreen() {
    // Decision tree:
    // 1. If user hasn't seen onboarding -> OnboardingScreen
    // 2. Else if user is not logged in -> LoginScreen
    // 3. Else -> PermissionScreen (user is logged in)

    if (!_seenOnboarding) {
      print('🎬 Routing to: OnboardingScreen');
      return const OnboardingScreen();
    } else if (!_isLoggedIn) {
      print('🔐 Routing to: LoginScreen');
      return const LoginScreen();
    } else {
      print('✅ Routing to: PermissionScreen');
      return const PermissionScreen();
    }
  }
}
 

