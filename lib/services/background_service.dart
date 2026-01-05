import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==================== CRITICAL FIX ====================
// onStart MUST be a TOP-LEVEL FUNCTION (not inside a class)
// This fixes: "Dart Error: To access ...::BackgroundServiceManager from native code, it must be annotated"
// ======================================================

/// Helper function to safely parse lastTimeUsed (handles both int and String)
int _parseTime(dynamic time) {
  if (time == null) return 0;
  if (time is int) return time;
  if (time is String) return int.tryParse(time) ?? 0;
  return 0;
}

/// Main service entry point - MUST BE TOP-LEVEL GLOBAL FUNCTION
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // ==================== CRITICAL FIX ====================
  // MUST initialize Flutter bindings and plugin registrant first
  // This prevents crashes when accessing plugins in background isolate
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  // ======================================================

  print(
    '🚀🚀🚀 FocusTalk Background Service Started - onStart EXECUTED 🚀🚀🚀',
  );

  // ==================== NOTIFICATION FIX FOR ANDROID 13+ ====================
  // Create notification immediately to prevent crash
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "FocusTalk Active",
      content: "Monitoring is running...",
    );
    print('✅ Foreground notification set successfully');
  }
  // ==========================================================================

  // Initialize SharedPreferences for reward time tracking
  final prefs = await SharedPreferences.getInstance();
  print('✅ SharedPreferences initialized in background service');

  // Initialize database and ensure it's seeded (important for background isolate)
  final dbHelper = DatabaseHelper();
  await dbHelper.seedDatabase();
  print('✅ Database initialized and seeded in background service');

  String? lastDetectedApp;
  DateTime? lastDetectionTime;

  // Listen for stop command
  service.on('stopService').listen((event) {
    print('⏹️ Service stop requested via stopService');
    service.stopSelf();
  });

  // Listen for legacy stop command (backward compatibility)
  service.on('stop').listen((event) {
    print('⏹️ Service stop requested via stop');
    service.stopSelf();
  });

  // Main monitoring loop - 1 second interval for faster blocking response
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    try {
      // Get current foreground app
      final now = DateTime.now();
      final endDate = now;
      final startDate = now.subtract(const Duration(seconds: 3));

      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
        startDate,
        endDate,
      );

      if (usageStats.isNotEmpty) {
        // Sort by last time used to get the most recent app
        usageStats.sort((a, b) {
          // Handle both String and int types from lastTimeUsed
          final aTime = _parseTime(a.lastTimeUsed);
          final bTime = _parseTime(b.lastTimeUsed);
          return bTime.compareTo(aTime);
        });

        final currentApp = usageStats.first.packageName;

        // TODO: IMPORTANT - Replace 'com.example.focustalk_app' with your actual applicationId
        // Find it in: android/app/build.gradle.kts -> defaultConfig -> applicationId
        // This prevents the app from blocking itself
        if (currentApp == 'com.example.focustalk_app') {
          return;
        }

        // Only process if this is a new app or 7 seconds have passed
        if (currentApp != lastDetectedApp ||
            lastDetectionTime == null ||
            now.difference(lastDetectionTime!).inSeconds >= 7) {
          lastDetectedApp = currentApp;
          lastDetectionTime = now;

          print('📱 Current App: $currentApp');

          // Check category from database
          final category = await dbHelper.getCategory(currentApp ?? '');

          print('🔍 Database lookup result: $category');

          if (category != null) {
            print('📂 Category: $category');

            // ==================== INTERVENTION LOGIC ====================
            // Check if overlay should be shown for GAME or SOCIAL apps
            if (category == 'GAME' || category == 'SOCIAL') {
              // ✅ NEW: Check if blocking is enabled for this app
              final isActive = await dbHelper.isAppActive(currentApp ?? '');

              if (isActive == null) {
                print('⚠️ App not found in database: $currentApp');
                return;
              }

              if (!isActive) {
                print('🔓 Blocking disabled for $currentApp (is_active = 0)');
                return;
              }

              print(
                '⚠️ Triggering intervention for category: $category (is_active = 1)',
              );

              // Check if overlay is already active
              final overlayIsActive = await FlutterOverlayWindow.isActive();
              print('🔎 Overlay active status: $overlayIsActive');

              if (!overlayIsActive) {
                print('🚨 Blocked app detected! Category: $category');
                print('🎯 Showing overlay quiz...');

                try {
                  // Save current blocked app package name for reward time tracking
                  await prefs.setString(
                    'current_blocked_app',
                    currentApp ?? '',
                  );
                  print('💾 Saved current blocked app: $currentApp');

                  // Show the overlay with full screen coverage
                  await FlutterOverlayWindow.showOverlay(
                    enableDrag: false,
                    overlayTitle: "FocusTalk Quiz",
                    overlayContent: 'Answer the question to continue',
                    flag: OverlayFlag.defaultFlag,
                    visibility: NotificationVisibility.visibilityPublic,
                    positionGravity: PositionGravity.auto,
                    // Use matchParent for responsive sizing
                    height: WindowSize.matchParent,
                    width: WindowSize.matchParent,
                    alignment: OverlayAlignment.center,
                  );

                  print('✅ Overlay shown successfully');
                } catch (e) {
                  print('❌ Error showing overlay: $e');
                  print('❌ Error details: ${e.toString()}');
                }
              } else {
                print('⏸️ Overlay already active, skipping');
              }
            } else {
              print('✓ Category $category is not blocked');
            }
            // ==================== END INTERVENTION LOGIC ====================
          } else {
            print('❓ App not in dictionary: $currentApp');
          }
        }
      }

      // Update service notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "FocusTalk Active",
          content: "Monitoring: ${lastDetectedApp ?? 'Waiting...'}",
        );
      }
    } catch (e) {
      print('❌ Error in monitoring loop: $e');
    }
  });
}

/// iOS background handler - MUST BE TOP-LEVEL
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Background Service Manager - Singleton for managing the service
class BackgroundServiceManager {
  static final BackgroundServiceManager _instance =
      BackgroundServiceManager._internal();

  factory BackgroundServiceManager() {
    return _instance;
  }

  BackgroundServiceManager._internal();

  /// Initialize and configure the background service
  Future<void> initializeService() async {
    print('═══════════════════════════════════════════════════════');
    print('🔧 BackgroundServiceManager.initializeService() CALLED');
    print('═══════════════════════════════════════════════════════');

    final service = FlutterBackgroundService();
    print('📦 FlutterBackgroundService instance created');

    print('⚙️ Configuring service with autoStart=false...');
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        onStart: onStart,
        isForegroundMode: true,
        autoStartOnBoot: false,
        notificationChannelId: 'focustalk_service',
        initialNotificationTitle: 'FocusTalk',
        initialNotificationContent: 'Monitoring your app usage...',
        foregroundServiceNotificationId: 888,
      ),
    );
    print('✅ Service configuration completed');
    print(
      '📝 Note: Service will NOT auto-start. Use toggle to start manually.',
    );
  }

  /// Start the background service
  Future<void> startService() async {
    print('═══════════════════════════════════════════════════════');
    print('▶️ BackgroundServiceManager.startService() CALLED');
    print('═══════════════════════════════════════════════════════');

    final service = FlutterBackgroundService();
    print('📞 Calling service.startService()...');
    await service.startService();
    print('✅ service.startService() completed');
    print('⏳ Waiting for onStart() callback to be triggered by Android...');
  }

  /// Stop the background service
  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  /// Check if service is running
  Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
