import 'package:flutter/material.dart';
import 'package:focustalk_app/utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Notification Settings
            _buildSettingSection(
              title: 'Notifications',
              items: [
                _buildSettingTile(
                  icon: Icons.notifications,
                  title: 'Quiz Notifications',
                  subtitle: 'Get notified for quiz attempts',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.schedule,
                  title: 'Focus Time Reminders',
                  subtitle: 'Daily goal reminders',
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),

            // App Settings
            _buildSettingSection(
              title: 'App Settings',
              items: [
                _buildSettingTile(
                  icon: Icons.brightness_6,
                  title: 'Dark Mode',
                  subtitle: 'Coming soon',
                  trailing: const Icon(Icons.lock, size: 20, color: Colors.grey),
                ),
                _buildSettingTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),

            // Privacy & Security
            _buildSettingSection(
              title: 'Privacy & Security',
              items: [
                _buildSettingTile(
                  icon: Icons.lock,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  onTap: () {},
                ),
                _buildSettingTile(
                  icon: Icons.description,
                  title: 'Terms of Service',
                  subtitle: 'View terms',
                  onTap: () {},
                ),
              ],
            ),

            // About
            _buildSettingSection(
              title: 'About',
              items: [
                _buildSettingTile(
                  icon: Icons.info,
                  title: 'App Version',
                  subtitle: 'v1.0.0',
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }
}
