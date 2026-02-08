import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/services/api_service.dart';

class EditProfileController extends GetxController {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observable states
  final isLoading = false.obs;
  final obscurePassword = true.obs;

  // Profile image
  Rx<File?> selectedImage = Rx<File?>(null);
  final currentPhotoUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserData();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Load current user data from SharedPreferences
  Future<void> _loadCurrentUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load current user data
      nameController.text = prefs.getString('user_name') ?? '';
      emailController.text = prefs.getString('user_email') ?? '';
      currentPhotoUrl.value = prefs.getString('user_photo') ?? '';

      print('✅ Loaded current user data');
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Validate form inputs
  bool _validateInputs() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Name cannot be empty',
        backgroundColor: Colors.red,
      );
      return false;
    }

    if (emailController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Email cannot be empty',
        backgroundColor: Colors.red,
      );
      return false;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text.trim())) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid email address',
        backgroundColor: Colors.red,
      );
      return false;
    }

    // Password validation (only if user is trying to change it)
    if (passwordController.text.isNotEmpty &&
        passwordController.text.length < 6) {
      Get.snackbar(
        'Validation Error',
        'Password must be at least 6 characters',
        backgroundColor: Colors.red,
      );
      return false;
    }

    return true;
  }

  /// Save profile changes
  Future<void> saveChanges() async {
    // Validate inputs first
    if (!_validateInputs()) {
      return;
    }

    // Set loading state
    isLoading.value = true;

    try {
      print('💾 Saving profile changes...');

      // Call API service to update profile
      final updatedUserData = await _apiService.updateUserProfile(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        image: selectedImage.value,
        password:
            passwordController.text.isNotEmpty ? passwordController.text : null,
      );

      if (updatedUserData != null) {
        // Update local SharedPreferences with new data
        await _updateLocalStorage(updatedUserData);

        // Ensure SharedPreferences is fully committed before continuing
        await Future.delayed(const Duration(milliseconds: 100));

        // Clear password field for security
        passwordController.clear();

        // Reset loading state before showing dialog
        isLoading.value = false;

        // Show success dialog
        await Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                const Text('Success'),
              ],
            ),
            content: const Text('Profile updated successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(); // Close dialog
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        );

        // Navigate back to profile screen after dialog is closed
        Get.back(result: true); // Return true to indicate success
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      print('❌ Save changes error: $e');

      // Reset loading state
      isLoading.value = false;

      // Show error dialog
      await Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              const Text('Error'),
            ],
          ),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // Close dialog
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      // Do NOT navigate back on error - let user try again
    }
  }

  /// Update local SharedPreferences with new user data
  Future<void> _updateLocalStorage(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update user data in SharedPreferences
      if (userData['name'] != null) {
        await prefs.setString('user_name', userData['name']);
      }
      if (userData['email'] != null) {
        await prefs.setString('user_email', userData['email']);
      }
      if (userData['picture'] != null) {
        await prefs.setString('user_photo', userData['picture']);
      }

      print('✅ Local storage updated successfully');

      // Update ProfileController if it exists (using GetX)
      try {
        // Check if ProfileController is registered
        if (Get.isRegistered<dynamic>()) {
          // Trigger profile refresh
          // This assumes you have a ProfileController with a refresh method
          // If not using GetX state management everywhere, you can skip this
          print('🔄 Notifying ProfileController to refresh');
        }
      } catch (e) {
        print('⚠️ ProfileController not found, skipping state update');
      }
    } catch (e) {
      print('❌ Error updating local storage: $e');
      rethrow;
    }
  }

  /// Pick image from gallery or camera
  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
        print('✅ Image selected: ${pickedFile.path}');
      } else {
        print('⚠️ No image selected');
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Show image source selection dialog
  Future<void> showImageSourceDialog() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                pickImage(source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                pickImage(source: ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Remove selected image
  void removeImage() {
    selectedImage.value = null;
    print('🗑️ Image removed');
  }
}
