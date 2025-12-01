import 'package:flutter/material.dart';
import 'package:focustalk_app/screens/permission_screen.dart';

void main() {
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
