import 'package:flutter/material.dart';
import 'package:focustalk_app/services/database_helper.dart';
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
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// CRITICAL: Reset daily progress for demo purposes
  Future<void> _resetDailyProgress() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Daily Progress?'),
            content: const Text(
              'This will reset your solved questions count to 0 and re-enable blocking.\n\nThis action is useful for testing and demos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();

      // Reset progress
      await prefs.setInt('solved_today', 0);

      // Keep the current date so it doesn't auto-reset
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('last_solved_date', today);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Progress Reset! Blocking is active again.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
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
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Set Daily Goal'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$tempGoal Questions',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Slider(
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
                      const SizedBox(height: 8),
                      const Text(
                        'Choose between 5-50 questions per day',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _updateDailyGoal(tempGoal);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ==================== GENERAL SECTION ====================
                  _buildSectionHeader('General'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.flag, color: Colors.purple),
                          title: const Text('Daily Goal'),
                          subtitle: Text('$_dailyGoal questions per day'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: _showDailyGoalDialog,
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(
                            Icons.notifications,
                            color: Colors.orange,
                          ),
                          title: const Text('Study Reminders'),
                          subtitle: const Text('3-hour reminder notifications'),
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================== DEVELOPER / DEMO TOOLS ====================
                  _buildSectionHeader('Developer / Demo Tools'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.refresh, color: Colors.red),
                          title: const Text('Reset Daily Progress'),
                          subtitle: const Text(
                            'Set solved count to 0 (for testing/demos)',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: _resetDailyProgress,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================== ABOUT SECTION ====================
                  _buildSectionHeader('About'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.info, color: Colors.blue),
                          title: Text('App Version'),
                          subtitle: Text('v1.0.0'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.school,
                            color: Colors.green,
                          ),
                          title: const Text('FocusTalk'),
                          subtitle: const Text(
                            'Consistent Learning Habit - Focus Aid App',
                          ),
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'FocusTalk',
                              applicationVersion: 'v1.0.0',
                              applicationIcon: const Icon(
                                Icons.school,
                                size: 48,
                                color: Colors.purple,
                              ),
                              children: [
                                const Text(
                                  'FocusTalk helps you build consistent learning habits by encouraging daily quiz completion.',
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Meet your daily goal to unlock unrestricted access to your favorite apps!',
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Additional Info
                  Center(
                    child: Text(
                      'Made with ❤️ for Academic Focus',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  /// Build section header widget
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
