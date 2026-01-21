import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification plugin
  static Future<void> initialize() async {
    // Android initialization settings
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap (optional)
        print('📩 Notification tapped: ${response.payload}');
      },
    );

    print('✅ NotificationHelper initialized successfully');
  }

  /// Show a local notification
  static Future<void> showNotification(String title, String body) async {
    // Android notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'study_reminders', // Channel ID
          'Study Reminders', // Channel Name
          channelDescription: 'Reminders to complete daily study goals',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'Study Reminder',
          icon: '@mipmap/ic_launcher',
        );

    // Combined notification details
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Show the notification
    await _notificationsPlugin.show(
      0, // Notification ID (use 0 or increment for multiple notifications)
      title,
      body,
      notificationDetails,
      payload: 'study_reminder', // Optional data
    );

    print('🔔 Notification sent: $title - $body');
  }
}
