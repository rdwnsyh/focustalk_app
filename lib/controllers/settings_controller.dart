import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  /// Observable for sound enabled status
  RxBool isSoundEnabled = true.obs;

  /// Called when controller is initialized
  @override
  void onInit() {
    super.onInit();
    _loadSoundSetting();
  }

  /// Load sound setting from SharedPreferences
  Future<void> _loadSoundSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('sound_enabled') ?? true;
      isSoundEnabled.value = soundEnabled;
      print('🔊 Sound setting loaded: $soundEnabled');
    } catch (e) {
      print('❌ Error loading sound setting: $e');
      isSoundEnabled.value = true; // Default to true on error
    }
  }

  /// Toggle sound on/off and save to SharedPreferences
  Future<void> toggleSound(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', value);
      isSoundEnabled.value = value;
      print('🔊 Sound toggled to: $value');
    } catch (e) {
      print('❌ Error toggling sound: $e');
    }
  }
}
