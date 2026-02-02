import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardService {
  // Backend API URL - Update this with your laptop's IP address
  static const String _baseUrl = 'http://192.168.1.10:8000';

  /// Fetch leaderboard data from backend
  Future<List<dynamic>> fetchLeaderboard() async {
    try {
      print('📥 Fetching leaderboard from: $_baseUrl/leaderboard');
      final response = await http.get(
        Uri.parse('$_baseUrl/leaderboard'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📊 Leaderboard Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ Leaderboard fetched successfully: ${data['leaderboard'].length} users',
        );
        return data['leaderboard'] as List<dynamic>;
      } else {
        print('❌ Leaderboard fetch failed: ${response.statusCode}');
        print('Response Body: ${response.body}');
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Leaderboard fetch error: $e');
      rethrow;
    }
  }

  /// Sync user progress to backend (fire-and-forget)
  Future<void> syncProgress(int solvedIncrement, int currentStreak) async {
    try {
      print('\n═══════════════════════════════════════════════════════');
      print('🔄 SYNC PROGRESS DEBUG');
      print('═══════════════════════════════════════════════════════');

      // Get SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // DEBUG: Check for 'user_data' (old approach)
      final userDataString = prefs.getString('user_data');
      print('DEBUG PREFS [user_data]: $userDataString');

      // DEBUG: Check for individual keys (current approach)
      final userEmail = prefs.getString('user_email');
      final userName = prefs.getString('user_name');
      final isLoggedIn = prefs.getBool('is_logged_in');

      print('DEBUG PREFS [user_email]: $userEmail');
      print('DEBUG PREFS [user_name]: $userName');
      print('DEBUG PREFS [is_logged_in]: $isLoggedIn');

      // Extract email from the correct source
      String? email;

      // Try getting email from individual key (current auth approach)
      if (userEmail != null && userEmail.isNotEmpty) {
        email = userEmail;
        print('✅ Email found from user_email key: $email');
      }
      // Fallback: Try getting email from user_data JSON (old approach)
      else if (userDataString != null) {
        try {
          final userData = json.decode(userDataString);
          // Check root level
          if (userData['email'] != null) {
            email = userData['email'];
            print('✅ Email found from user_data root: $email');
          }
          // Check nested user object
          else if (userData['user'] != null &&
              userData['user']['email'] != null) {
            email = userData['user']['email'];
            print('✅ Email found from user_data.user: $email');
          }
        } catch (e) {
          print('⚠️ Failed to parse user_data JSON: $e');
        }
      }

      // Validation
      if (email == null || email.isEmpty) {
        print('❌ Email not found in SharedPreferences');
        print('❌ Cannot sync progress - User not logged in or data missing');
        print('═══════════════════════════════════════════════════════\n');
        return;
      }

      print('📤 Syncing progress for: $email');
      print('   → solved_increment: $solvedIncrement');
      print('   → current_streak: $currentStreak');

      final requestBody = json.encode({
        'email': email,
        'solved_increment': solvedIncrement,
        'streak': currentStreak,
      });

      print('📤 Request Body: $requestBody');

      // Fire-and-forget POST request
      http
          .post(
            Uri.parse('$_baseUrl/user/sync_progress'),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .then((response) {
            print('📥 Sync Response Status: ${response.statusCode}');
            print('📥 Sync Response Body: ${response.body}');

            if (response.statusCode == 200) {
              print('✅ Progress synced successfully to server');
            } else {
              print('❌ Failed to sync progress: ${response.statusCode}');
            }
            print('═══════════════════════════════════════════════════════\n');
          })
          .catchError((error) {
            print('❌ HTTP Error syncing progress: $error');
            print('═══════════════════════════════════════════════════════\n');
          });
    } catch (e) {
      print('❌ Sync progress exception: $e');
      print('═══════════════════════════════════════════════════════\n');
    }
  }

  /// Get current user's stats for comparison
  Future<Map<String, dynamic>?> getCurrentUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try individual keys first (current auth approach)
      final userEmail = prefs.getString('user_email');
      final userName = prefs.getString('user_name');
      final userPhoto = prefs.getString('user_photo');

      if (userEmail != null) {
        return {
          'name': userName ?? 'User',
          'email': userEmail,
          'picture': userPhoto ?? '',
        };
      }

      // Fallback: Try user_data JSON (old approach)
      final userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        return {
          'name': userData['name'] ?? userData['user']?['name'] ?? 'User',
          'email': userData['email'] ?? userData['user']?['email'] ?? '',
          'picture': userData['picture'] ?? userData['user']?['picture'] ?? '',
        };
      }

      return null;
    } catch (e) {
      print('❌ Error getting current user stats: $e');
      return null;
    }
  }
}
