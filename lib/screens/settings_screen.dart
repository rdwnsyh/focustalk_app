import 'package:flutter/material.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:focustalk_app/screens/apps_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  int _dailyGoal = 20;
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  // Modern Color Palette based on your preferences
  final Color _primaryPurple = const Color(0xFFFF8C42);
  final Color _bgColor = const Color.fromARGB(255, 253, 245, 230);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Load current settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    setState(() {
      _dailyGoal = prefs.getInt('daily_goal') ?? 20;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _isLoading = false;
    });
  }

  /// Update daily goal
  Future<void> _updateDailyGoal(int newGoal) async {
    await _dbHelper.setDailyGoal(newGoal);
    setState(() {
      _dailyGoal = newGoal;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily goal updated to $newGoal questions'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating, // Modern floating snackbar
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Toggle notifications
  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    setState(() {
      _notificationsEnabled = value;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value ? 'Notifications enabled' : 'Notifications disabled',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// CRITICAL: Reset daily progress for demo purposes
  Future<void> _resetDailyProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Daily Progress?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will reset your solved questions count to 0 and re-enable blocking.\n\nThis action is useful for testing and demos.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('solved_today', 0);
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('last_solved_date', today);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Progress Reset! Blocking is active again.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('🔄 Daily progress reset to 0 for demo/testing');
    }
  }

  /// Show dialog to change daily goal
  Future<void> _showDailyGoalDialog() async {
    int tempGoal = _dailyGoal;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Center(child: Text('Set Daily Goal', style: TextStyle(fontWeight: FontWeight.bold))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$tempGoal',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _primaryPurple,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Questions per day',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _primaryPurple,
                  inactiveTrackColor: _primaryPurple.withOpacity(0.2),
                  thumbColor: _primaryPurple,
                  overlayColor: _primaryPurple.withOpacity(0.1),
                ),
                child: Slider(
                  value: tempGoal.toDouble(),
                  min: 5,
                  max: 50,
                  divisions: 9,
                  label: '$tempGoal',
                  onChanged: (value) {
                    setDialogState(() {
                      tempGoal = value.toInt();
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                _updateDailyGoal(tempGoal);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryPurple, const Color.fromARGB(255, 213, 123, 33)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ==================== BLOCKING CONFIGURATION ====================
                _buildSectionHeader('Blocking Configuration'),
                _buildSettingsContainer(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.grid_view_rounded,
                      iconColor: Colors.blue,
                      title: 'Monitored Apps',
                      subtitle: 'Manage which apps trigger blocking',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ==================== GENERAL SECTION ====================
                _buildSectionHeader('General'),
                _buildSettingsContainer(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.flag_rounded,
                      iconColor: Colors.purple,
                      title: 'Daily Goal',
                      subtitle: '$_dailyGoal questions per day',
                      onTap: _showDailyGoalDialog,
                    ),
                    _buildDivider(),
                    SwitchListTile(
                      activeColor: _primaryPurple,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      secondary: _buildIconContainer(Icons.notifications_active_rounded, Colors.orange),
                      title: const Text(
                        'Study Reminders',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      subtitle: const Text(
                        '3-hour reminder notifications',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ==================== DEVELOPER / DEMO TOOLS ====================
                _buildSectionHeader('Developer Options'),
                _buildSettingsContainer(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.refresh_rounded,
                      iconColor: Colors.redAccent,
                      title: 'Reset Daily Progress',
                      subtitle: 'Set solved count to 0 (Demo Mode)',
                      onTap: _resetDailyProgress,
                      isDestructive: true, // Special styling for destructive actions
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ==================== ABOUT SECTION ====================
                _buildSectionHeader('About'),
                _buildSettingsContainer(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.blueAccent,
                      title: 'App Version',
                      subtitle: 'v1.0.0',
                      showArrow: false,
                    ),
                    _buildDivider(),
                    _buildSettingsTile(
                      icon: Icons.school_rounded,
                      iconColor: Colors.green,
                      title: 'About FocusTalk',
                      subtitle: 'Consistent Learning Habit',
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'FocusTalk',
                          applicationVersion: 'v1.0.0',
                          applicationIcon: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _primaryPurple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.school_rounded, size: 40, color: _primaryPurple),
                          ),
                          children: [
                            const Text(
                              'FocusTalk helps you build consistent learning habits by encouraging daily quiz completion.',
                              style: TextStyle(fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Meet your daily goal to unlock unrestricted access to your favorite apps!',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // ==================== MODERN UI HELPER WIDGETS ====================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  /// The main white container for settings groups
  Widget _buildSettingsContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// A custom clean tile widget
  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showArrow = true,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildIconContainer(icon, iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDestructive ? Colors.red : Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[300],
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// The colored box around icons
  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  /// Subtle divider for inside the containers
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 60), // Align with text
      child: Divider(height: 1, color: Colors.grey[100]),
    );
  }
}