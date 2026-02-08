import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:focustalk_app/controllers/notification_settings_controller.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller using GetX
    final controller = Get.put(NotificationSettingsController());

    // Color palette
    final primaryOrange = const Color(0xFFFF6B35);
    final bgOldLace = const Color(0xFFFDF5E6);

    return Scaffold(
      backgroundColor: bgOldLace,
      appBar: AppBar(
        backgroundColor: primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Text(
                'Manage Your Notifications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose what notifications you want to receive',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Notification Settings Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Daily Reminder Setting
                    Obx(
                      () => SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.alarm,
                            color: primaryOrange,
                            size: 28,
                          ),
                        ),
                        title: const Text(
                          'Daily Study Reminder',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Get reminded to study at 08:00 PM',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        value: controller.dailyReminder.value,
                        activeColor: primaryOrange,
                        onChanged: (value) {
                          controller.toggleSetting(
                            controller.keyDailyReminder,
                            value,
                          );
                        },
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),

                    // Streak Alerts Setting
                    Obx(
                      () => SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: Colors.orange.shade700,
                            size: 28,
                          ),
                        ),
                        title: const Text(
                          'Streak & Gamification Alerts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Achievements, streaks, and milestones',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        value: controller.streakAlerts.value,
                        activeColor: primaryOrange,
                        onChanged: (value) {
                          controller.toggleSetting(
                            controller.keyStreakAlerts,
                            value,
                          );
                        },
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.shade300),

                    // App Updates Setting
                    Obx(
                      () => SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.new_releases,
                            color: Colors.blue.shade700,
                            size: 28,
                          ),
                        ),
                        title: const Text(
                          'App News & Updates',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'New features, tips, and announcements',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        value: controller.appUpdates.value,
                        activeColor: primaryOrange,
                        onChanged: (value) {
                          controller.toggleSetting(
                            controller.keyAppUpdates,
                            value,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Changes are saved automatically. You can modify these settings anytime.',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
