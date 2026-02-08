import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/screens/onboarding_screen.dart';
import 'package:focustalk_app/screens/login_screen.dart';
import 'package:focustalk_app/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _navigateAfterSplash();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);
    _scaleAnimation =
        Tween<double>(begin: 0.5, end: 1.0).animate(curvedAnimation);

    _controller.forward();
  }

  Future<void> _navigateAfterSplash() async {
    // Wait 3 seconds total to display splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check login status
    await _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check onboarding status first
      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      
      if (!seenOnboarding) {
        // New user → Onboarding
        print('🆕 First time user - navigating to Onboarding');
        if (mounted) Get.offAll(() => const OnboardingScreen());
        return;
      }

      // Check for user token or login flag
      final userToken = prefs.getString('user_token');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!mounted) return;

      if (isLoggedIn || userToken != null) {
        // User is logged in → go to Main (with bottom nav)
        print('✅ User logged in - navigating to Main');
        Get.offAll(() => const MainScreen());
      } else {
        // User not logged in but saw onboarding → go to Login
        print('🔐 User not logged in - navigating to Login');
        Get.offAll(() => const LoginScreen());
      }
    } catch (e) {
      print('❌ Error checking login status: $e');
      if (mounted) {
        // Fallback to onboarding on error
        Get.offAll(() => const OnboardingScreen());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const creamColor = Color(0xFFFFF3E0);

    return Scaffold(
      backgroundColor: creamColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildLogo(),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    // Show logo with title; fallback to icon if asset missing
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 160,
          height: 160,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.chat_bubble,
              size: 100,
              color: Color(0xFF1E88E5),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'FocusTalk',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 30, 30, 30),
          ),
        ),
      ],
    );
  }
}
