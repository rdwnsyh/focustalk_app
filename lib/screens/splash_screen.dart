import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/utils/app_colors.dart';
import 'package:focustalk_app/screens/onboarding_screen.dart';
import 'package:focustalk_app/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('is_onboarding_done') ?? false;

    if (!mounted) return;

    if (onboardingDone) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
                Image.asset(
                'assets/logo.png',
                width: 100,
                height: 100,
                ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
