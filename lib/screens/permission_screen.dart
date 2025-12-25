import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:focustalk_app/screens/home_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _overlayPermissionGranted = false;
  bool _usageAccessGranted = false;
  bool _notificationPermissionGranted = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// Check all required permissions
  Future<void> _checkPermissions() async {
    setState(() {
      _isChecking = true;
    });

    try {
      // Check overlay permission
      final overlayStatus = await FlutterOverlayWindow.isPermissionGranted();

      // Check usage access permission
      final usageStatus = await UsageStats.checkUsagePermission() ?? false;

      // Check notification permission (Android 13+)
      final notificationStatus = await Permission.notification.isGranted;

      setState(() {
        _overlayPermissionGranted = overlayStatus;
        _usageAccessGranted = usageStatus;
        _notificationPermissionGranted = notificationStatus;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking permissions: $e')),
        );
      }
    }
  }

  /// Request overlay permission
  Future<void> _requestOverlayPermission() async {
    try {
      final granted = await FlutterOverlayWindow.requestPermission();
      setState(() {
        _overlayPermissionGranted = granted ?? false;
      });

      if (granted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Overlay permission granted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting overlay permission: $e')),
        );
      }
    }
  }

  /// Request usage access permission
  Future<void> _requestUsageAccess() async {
    try {
      await UsageStats.grantUsagePermission();

      // Wait a moment then recheck
      await Future.delayed(const Duration(seconds: 1));
      final granted = await UsageStats.checkUsagePermission() ?? false;

      setState(() {
        _usageAccessGranted = granted;
      });

      if (granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usage access granted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error requesting usage access: $e')),
        );
      }
    }
  }

  /// Request notification permission (Android 13+)
  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      setState(() {
        _notificationPermissionGranted = status.isGranted;
      });

      if (status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission granted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting notification permission: $e'),
          ),
        );
      }
    }
  }

  /// Navigate to home screen when all permissions granted
  void _continueToApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPermissionsGranted =
        _overlayPermissionGranted &&
        _usageAccessGranted &&
        _notificationPermissionGranted;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('FocusTalk Setup'),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isChecking
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header section
                    const Icon(
                      Icons.shield_outlined,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Required Permissions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'FocusTalk needs these permissions to help you stay focused',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Notification Permission Card (Android 13+)
                    _buildPermissionCard(
                      icon: Icons.notifications_outlined,
                      title: 'Notification Permission',
                      description:
                          'Allows FocusTalk to show background service notifications',
                      isGranted: _notificationPermissionGranted,
                      buttonText:
                          _notificationPermissionGranted
                              ? 'Granted ✓'
                              : 'Grant Notification',
                      onPressed:
                          _notificationPermissionGranted
                              ? null
                              : _requestNotificationPermission,
                    ),

                    const SizedBox(height: 16),

                    // Overlay Permission Card
                    _buildPermissionCard(
                      icon: Icons.layers_outlined,
                      title: 'Overlay Permission',
                      description:
                          'Allows FocusTalk to display quiz overlay on top of other apps',
                      isGranted: _overlayPermissionGranted,
                      buttonText:
                          _overlayPermissionGranted
                              ? 'Granted ✓'
                              : 'Grant Overlay Permission',
                      onPressed:
                          _overlayPermissionGranted
                              ? null
                              : _requestOverlayPermission,
                    ),

                    const SizedBox(height: 16),

                    // Usage Access Permission Card
                    _buildPermissionCard(
                      icon: Icons.insights_outlined,
                      title: 'Usage Access',
                      description:
                          'Allows FocusTalk to detect which apps you are currently using',
                      isGranted: _usageAccessGranted,
                      buttonText:
                          _usageAccessGranted
                              ? 'Granted ✓'
                              : 'Grant Usage Access',
                      onPressed:
                          _usageAccessGranted ? null : _requestUsageAccess,
                    ),

                    const SizedBox(height: 32),

                    // Recheck permissions button
                    OutlinedButton.icon(
                      onPressed: _checkPermissions,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recheck Permissions'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Continue button (only shown when all permissions granted)
                    if (allPermissionsGranted)
                      ElevatedButton(
                        onPressed: _continueToApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue to App',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Status message
                    if (!allPermissionsGranted)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Please grant all permissions to use FocusTalk',
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  /// Build individual permission card
  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required String buttonText,
    required VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isGranted ? Colors.green[300]! : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isGranted ? Colors.green[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isGranted ? Colors.green[700] : Colors.blue[700],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (isGranted)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isGranted ? Colors.green[600] : Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: isGranted ? 0 : 2,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
