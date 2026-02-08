import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsController extends GetxController {
  // State variables for notification settings
  final dailyReminder = true.obs;
  final streakAlerts = true.obs;
  final appUpdates = false.obs;

  // SharedPreferences keys
  static const String _keyDailyReminder = 'pref_daily_reminder';
  static const String _keyStreakAlerts = 'pref_streak_alerts';
  static const String _keyAppUpdates = 'pref_app_updates';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  /// Load notification settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load settings with default values
      dailyReminder.value = prefs.getBool(_keyDailyReminder) ?? true;
      streakAlerts.value = prefs.getBool(_keyStreakAlerts) ?? true;
      appUpdates.value = prefs.getBool(_keyAppUpdates) ?? false;

      print('✅ Loaded notification settings:');
      print('   Daily Reminder: ${dailyReminder.value}');
      print('   Streak Alerts: ${streakAlerts.value}');
      print('   App Updates: ${appUpdates.value}');
    } catch (e) {
      print('❌ Error loading notification settings: $e');
    }
  }

  /// Toggle a specific notification setting
  Future<void> toggleSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update the corresponding RxBool based on key
      switch (key) {
        case _keyDailyReminder:
          dailyReminder.value = value;
          await prefs.setBool(_keyDailyReminder, value);
          print('✅ Daily Reminder updated: $value');
          break;

        case _keyStreakAlerts:
          streakAlerts.value = value;
          await prefs.setBool(_keyStreakAlerts, value);
          print('✅ Streak Alerts updated: $value');
          break;

        case _keyAppUpdates:
          appUpdates.value = value;
          await prefs.setBool(_keyAppUpdates, value);
          print('✅ App Updates updated: $value');
          break;

        default:
          print('⚠️ Unknown setting key: $key');
      }
    } catch (e) {
      print('❌ Error saving notification setting: $e');
    }
  }

  /// Public getters for SharedPreferences keys (used by View)
  String get keyDailyReminder => _keyDailyReminder;
  String get keyStreakAlerts => _keyStreakAlerts;
  String get keyAppUpdates => _keyAppUpdates;
}
