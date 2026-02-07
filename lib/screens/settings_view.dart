import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focustalk_app/controllers/settings_controller.dart';

class SettingsView extends StatelessWidget {
  SettingsView({super.key});

  final SettingsController controller = Get.put(SettingsController());

  // Color palette
  static const Color creamBackground = Color(0xFFFFF3E0);
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color darkOrange = Color(0xFFFF8C42);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamBackground,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryOrange,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          /// Sound Effects Toggle
          _buildSoundEffectsSection(),
        ],
      ),
    );
  }

  /// Build Sound Effects section with SwitchListTile
  Widget _buildSoundEffectsSection() {
    return Obx(
      () => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile(
          title: const Text(
            'Enable Sound Effects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          subtitle: const Text(
            'Play sounds during quizzes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          activeColor: primaryOrange,
          value: controller.isSoundEnabled.value,
          onChanged: (value) {
            controller.toggleSound(value);
          },
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 12.0,
          ),
        ),
      ),
    );
  }
}
