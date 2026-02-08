import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Base URL - should match your FastAPI backend
  static const String _baseUrl = 'http://192.168.1.10:8000';

  /// Update user profile (name, email, password, and/or profile picture)
  ///
  /// This method handles multipart/form-data requests to support file uploads
  ///
  /// Parameters:
  /// - [name]: Updated full name
  /// - [email]: Updated email address
  /// - [image]: Optional profile image file
  /// - [password]: Optional new password (only include if user wants to change it)
  ///
  /// Returns:
  /// - `true` if update was successful
  /// - `false` if update failed
  ///
  /// Throws:
  /// - Exception if network error or server error occurs
  Future<Map<String, dynamic>?> updateUserProfile({
    required String name,
    required String email,
    File? image,
    String? password,
  }) async {
    try {
      print('🔄 Updating user profile...');
      print('   Name: $name');
      print('   Email: $email');
      print('   Has Image: ${image != null}');
      print('   Has Password: ${password != null}');

      // Get auth token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('No auth token found. Please login again.');
      }

      // Create URI with token as query parameter
      final uri = Uri.parse('$_baseUrl/users/me?token=$token');
      final request = http.MultipartRequest('PUT', uri);

      // Add form fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['token'] = token;

      // Add password field only if provided
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      // Add image file if provided
      if (image != null) {
        print('📤 Adding image to request...');
        final imageFile = await http.MultipartFile.fromPath(
          'image', // Field name expected by backend
          image.path,
          // You can specify content type if needed:
          // contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(imageFile);
      }

      // Send request
      print('📡 Sending request to: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Success - parse response
        final Map<String, dynamic> userData = jsonDecode(response.body);
        print('✅ Profile updated successfully');

        return userData;
      } else if (response.statusCode == 401) {
        // Unauthorized - token expired or invalid
        throw Exception('Session expired. Please login again.');
      } else {
        // Other error
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['detail'] ?? 'Failed to update profile';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Update profile error: $e');
      rethrow;
    }
  }

  /// Get current user profile from backend
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      print('🔍 Fetching user profile...');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('No auth token found. Please login again.');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('✅ Profile fetched successfully');
        return userData;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to fetch profile');
      }
    } catch (e) {
      print('❌ Fetch profile error: $e');
      rethrow;
    }
  }
}
