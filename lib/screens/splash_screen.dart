import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/screens/onboarding_screen.dart';
import 'package:focustalk_app/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Tunggu 2 detik untuk menampilkan splash screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Cek apakah user sudah pernah membuka app sebelumnya
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      // User baru → ke Onboarding
      print('🆕 First time user - navigating to Onboarding');
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else {
      // User sudah pernah → ke Main Screen
      print('👤 Returning user - navigating to Main Screen');
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo atau Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.psychology_alt,
                size: 60,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 30),
            // App Name
            const Text(
              'FocusTalk',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              'Focus on Your Mind',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
