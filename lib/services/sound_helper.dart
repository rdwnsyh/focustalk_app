import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundHelper {
  /// Static AudioPlayer instance
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Play a sound file if sound effects are enabled
  ///
  /// [fileName] - The name of the audio file (without path, assumed to be in assets/sounds/)
  /// Example: playSound('correct.mp3')
  static Future<void> playSound(String fileName) async {
    try {
      // Check SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final isSoundEnabled = prefs.getBool('sound_enabled') ?? true;

      if (!isSoundEnabled) {
        print('🔇 Sound is disabled, skipping: $fileName');
        return;
      }

      // Play the sound from assets
      final audioPath = 'assets/sounds/$fileName';
      print('🔊 Playing sound: $audioPath');

      await _audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print('❌ Error playing sound: $e');
    }
  }

  /// Stop the currently playing sound
  static Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      print('🛑 Sound stopped');
    } catch (e) {
      print('❌ Error stopping sound: $e');
    }
  }

  /// Pause the currently playing sound
  static Future<void> pauseSound() async {
    try {
      await _audioPlayer.pause();
      print('⏸️ Sound paused');
    } catch (e) {
      print('❌ Error pausing sound: $e');
    }
  }

  /// Resume the paused sound
  static Future<void> resumeSound() async {
    try {
      await _audioPlayer.resume();
      print('▶️ Sound resumed');
    } catch (e) {
      print('❌ Error resuming sound: $e');
    }
  }

  /// Set volume level (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      print('🔊 Volume set to: ${volume.clamp(0.0, 1.0)}');
    } catch (e) {
      print('❌ Error setting volume: $e');
    }
  }
}
