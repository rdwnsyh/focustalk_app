import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:focustalk_app/services/notification_helper.dart';
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

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  print('✅ SharedPreferences initialized in background service');

  // Initialize database and ensure it's seeded (important for background isolate)
  final dbHelper = DatabaseHelper();
  await dbHelper.seedDatabase();
  print('✅ Database initialized and seeded in background service');

  // Initialize NotificationHelper for study reminders
  await NotificationHelper.initialize();
  print('✅ NotificationHelper initialized in background service');

  String? lastDetectedApp;
  DateTime? lastDetectionTime;

  // NEW: Timer for 10-minute rule
  int appSessionSeconds = 0;
  String? trackedApp;

  // NEW: Notification tracking (3-hour reminder)
  DateTime? lastReminderTime;

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

  // Main monitoring loop - 1 second interval
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    try {
      // ==================== CHECK OVERLAY STATUS FIRST ====================
      // PAUSE monitoring while overlay is open to prevent timer from counting during quiz
      bool isOverlayOpen = await FlutterOverlayWindow.isActive();
      if (isOverlayOpen) {
        print("⏸️ Overlay is open. Pausing timer...");
        return; // EXIT the loop iteration. Do not count time. Do not check apps.
      }
      // ====================================================================

      // ==================== REFRESH VALUES FROM SHAREDPREFERENCES ====================
      // Background service runs in separate isolate, so we must re-fetch fresh data
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // <--- CRITICAL: Force reload from disk, not cache!

      // Get current date
      String today =
          DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      String lastDate = prefs.getString('last_solved_date') ?? "";

      // RESET LOGIC: If it's a new day, reset counters automatically here
      if (lastDate != today) {
        await prefs.setInt('solved_today', 0);
        await prefs.setString('last_solved_date', today);
        print("📅 New Day Detected! Counters Reset to 0.");
      }

      // Fetch LATEST values (not cached) - re-read after potential reset
      int solved = prefs.getInt('solved_today') ?? 0;
      int goal = prefs.getInt('daily_goal') ?? 20;

      print('🔍 Background Check: solved=$solved, goal=$goal');

      // FREEDOM LOGIC: If target reached, STOP blocking
      if (solved >= goal) {
        print('🎉 GOAL REACHED! $solved >= $goal - Exiting monitoring loop');

        // Update notification to show "Goal Reached! Free Time"
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "FocusTalk: Free Mode ✨",
            content: "Daily target ($solved/$goal) reached. You are free!",
          );
        }

        // Reset session tracking
        appSessionSeconds = 0;
        trackedApp = null;

        return; // <--- CRITICAL: EXIT THE LOOP immediately. Do not check apps.
      }
      // ===============================================================================

      // ==================== 3-HOUR REMINDER NOTIFICATION ====================
      // Only send reminders if goal is NOT reached
      bool goalReached = solved >= goal;
      if (!goalReached) {
        final now = DateTime.now();
        // Check if first run OR 3 hours passed since last reminder
        if (lastReminderTime == null ||
            now.difference(lastReminderTime!).inSeconds >= 10) {
          final remaining = goal - solved;

          // Trigger Local Notification
          await NotificationHelper.showNotification(
            "Don't forget to study!",
            "You have $remaining question${remaining > 1 ? 's' : ''} left today.",
          );

          lastReminderTime = now; // Update timestamp
          print('🔔 Study reminder sent! ($remaining questions remaining)');
        }
      }
      // =====================================================================

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

        // Prevent the app from blocking itself
        if (currentApp == 'com.example.focustalk_app') {
          return;
        }

        print('📱 Current App: $currentApp');

        // Check category from database
        final category = await dbHelper.getCategory(currentApp ?? '');
        print('🔍 Database lookup result: $category');

        if (category != null) {
          print('📂 Category: $category');

          // ==================== 10-MINUTE TIMER LOGIC ====================
          // Only track SOCIAL/GAME apps when goal is not met
          if (category == 'GAME' || category == 'SOCIAL') {
            final isActive = await dbHelper.isAppActive(currentApp ?? '');

            if (isActive == null || !isActive) {
              print('🔓 Blocking disabled for $currentApp');
              appSessionSeconds = 0;
              trackedApp = null;
              return;
            }

            // Check if we're still tracking the same app
            if (trackedApp == currentApp) {
              // Same app - increment timer
              appSessionSeconds++;
              final minutesUsed = (appSessionSeconds / 60).floor();
              final secondsLeft = 10 - appSessionSeconds;

              print(
                '⏱️ $currentApp usage: ${minutesUsed}m ${appSessionSeconds % 60}s (${secondsLeft}s until quiz)',
              );

              // Update notification with timer
              if (service is AndroidServiceInstance) {
                final minutesLeft = (secondsLeft / 60).ceil();
                service.setForegroundNotificationInfo(
                  title: "FocusTalk Monitoring",
                  content:
                      "⏳ ${currentApp?.split('.').last}: $minutesLeft min left before quiz",
                );
              }

              // Check if 10 seconds have passed (for testing/demo)
              if (appSessionSeconds >= 10) {
                print('🚨 10 seconds reached! Showing overlay quiz...');

                // Check if overlay is already active
                final overlayIsActive = await FlutterOverlayWindow.isActive();
                if (!overlayIsActive) {
                  try {
                    await prefs.setString(
                      'current_blocked_app',
                      currentApp ?? '',
                    );

                    await FlutterOverlayWindow.showOverlay(
                      enableDrag: false,
                      overlayTitle: "FocusTalk Quiz",
                      overlayContent: 'Answer the question to continue',
                      flag: OverlayFlag.defaultFlag,
                      visibility: NotificationVisibility.visibilityPublic,
                      positionGravity: PositionGravity.auto,
                      height: WindowSize.matchParent,
                      width: WindowSize.matchParent,
                      alignment: OverlayAlignment.center,
                    );

                    print('✅ Overlay shown successfully');
                    appSessionSeconds = 0; // Reset timer after showing quiz
                  } catch (e) {
                    print('❌ Error showing overlay: $e');
                  }
                }
              }
            } else {
              // Different app - reset timer
              print(
                '🔄 App changed from $trackedApp to $currentApp - resetting timer',
              );
              trackedApp = currentApp;
              appSessionSeconds = 0;
            }
          } else {
            // Not a monitored category - reset timer
            if (trackedApp != null) {
              print('✓ Category $category is not monitored - resetting timer');
              appSessionSeconds = 0;
              trackedApp = null;
            }
          }
          // ==================== END 10-MINUTE LOGIC ====================
        } else {
          print('ℹ️ App not found in database: $currentApp');
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
