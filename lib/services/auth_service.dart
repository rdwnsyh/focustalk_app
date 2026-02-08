import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ===========================
  // CONFIGURATION CONSTANTS
  // ===========================

  // Laptop's local IP address (found via ipconfig)
  // Both phone and laptop must be on the same WiFi network
  static const String _baseUrl = 'http://192.168.0.102:8000';

  // TODO: Replace with your Google Cloud Console WEB Client ID
  // Get this from: https://console.cloud.google.com/apis/credentials
  static const String _serverClientId =
      '970950673922-5mecnlsjs82007ji8tp87ba9153tl22i.apps.googleusercontent.com';

  // ===========================
  // GOOGLE SIGN-IN INSTANCE
  // ===========================

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  // ===========================
  // AUTHENTICATION METHODS
  // ===========================

  /// Sign in with Google and authenticate with backend
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('🔐 Starting Google Sign-In...');

      // Step 1: Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ User cancelled Google Sign-In');
        return null; // User cancelled the sign-in
      }

      print('✅ Google account selected: ${googleUser.email}');

      // Step 2: Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        print('❌ Failed to get ID Token');
        throw Exception('Failed to get ID Token from Google');
      }

      print('✅ ID Token obtained');
      print('📤 Sending ID Token to backend...');

      // Step 3: Send ID Token to FastAPI backend
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id_token': idToken}),
      );

      print('📥 Backend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Step 4: Parse backend response
        final Map<String, dynamic> userData = jsonDecode(response.body);
        print('✅ Backend authentication successful');
        print('👤 User: ${userData['email']}');

        // Step 5: Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', userData['token'] ?? '');
        await prefs.setString('user_email', userData['email'] ?? '');
        await prefs.setString('user_name', userData['name'] ?? '');
        await prefs.setString('user_photo', userData['picture'] ?? '');
        await prefs.setBool('is_logged_in', true);

        print('✅ User data saved to local storage');

        return userData;
      } else {
        print('❌ Backend authentication failed: ${response.body}');
        throw Exception(
          'Backend authentication failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out from Google and clear local data
  Future<void> signOut() async {
    try {
      print('🚪 Signing out...');

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      print('✅ Sign-out successful');
    } catch (e) {
      print('❌ Sign-out error: $e');
      rethrow;
    }
  }

  /// Register a new user with email and password
  Future<bool> register(String name, String email, String password) async {
    try {
      print('📝 Starting registration...');
      print('📧 Email: $email');

      // Send registration request to backend
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': name,
          'email': email,
          'password': password,
        }),
      );

      print('📥 Registration response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse backend response
        final Map<String, dynamic> userData = jsonDecode(response.body);
        print('✅ Registration successful');
        print('👤 User: ${userData['email']}');

        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', userData['token'] ?? '');
        await prefs.setString('user_email', userData['email'] ?? '');
        await prefs.setString('user_name', userData['name'] ?? '');
        await prefs.setString('user_photo', userData['picture'] ?? '');
        await prefs.setBool('is_logged_in', true);

        print('✅ User data saved to local storage');
        return true;
      } else {
        // Registration failed
        final errorData = jsonDecode(response.body);
        print('❌ Registration failed: ${errorData['detail'] ?? response.body}');
        throw Exception(errorData['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ Registration error: $e');
      rethrow;
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      print('🔐 Starting email/password login...');
      print('📧 Email: $email');

      // Send login request to backend
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('📥 Login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse backend response
        final Map<String, dynamic> userData = jsonDecode(response.body);
        print('✅ Login successful');
        print('👤 User: ${userData['email']}');

        // Save user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', userData['token'] ?? '');
        await prefs.setString('user_email', userData['email'] ?? '');
        await prefs.setString('user_name', userData['name'] ?? '');
        await prefs.setString('user_photo', userData['picture'] ?? '');
        await prefs.setBool('is_logged_in', true);

        print('✅ User data saved to local storage');
        return true;
      } else {
        // Login failed
        final errorData = jsonDecode(response.body);
        print('❌ Login failed: ${errorData['detail'] ?? response.body}');
        throw Exception(errorData['detail'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  /// Get currently logged in user data from SharedPreferences
  Future<Map<String, String>?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (!isLoggedIn) {
        return null;
      }

      return {
        'token': prefs.getString('auth_token') ?? '',
        'email': prefs.getString('user_email') ?? '',
        'name': prefs.getString('user_name') ?? '',
        'photo': prefs.getString('user_photo') ?? '',
      };
    } catch (e) {
      print('❌ Error getting user: $e');
      return null;
    }
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }
}
