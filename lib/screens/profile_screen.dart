import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:focustalk_app/services/auth_service.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic>? userData;
  
  // Statistics
  int totalSolved = 0;
  int totalCorrect = 0;
  int currentStreak = 0;
  double accuracyRate = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatistics();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataJson = prefs.getString('user_data');
    
    if (userDataJson != null) {
      setState(() {
        userData = jsonDecode(userDataJson);
      });
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _dbHelper.getTotalStats();
      final streak = await _dbHelper.getCurrentStreak();
      
      final total = stats['total_solved'] ?? 0;
      final correct = stats['total_correct'] ?? 0;
      
      setState(() {
        totalSolved = total;
        totalCorrect = correct;
        currentStreak = streak;
        accuracyRate = total > 0 ? (correct / total * 100) : 0.0;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Sign out from AuthService
      await _authService.signOut();

      // Clear all data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to LoginScreen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = userData?['full_name'] ?? 'User Name';
    final email = userData?['email'] ?? 'user@email.com';
    final photoUrl = userData?['photo_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Modern AppBar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 50, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar with border
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.orange.shade100,
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.orange.shade600,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile Info and Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Name and Email
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Statistics Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildStatCard(
                        icon: Icons.done_all,
                        label: 'Questions Solved',
                        value: totalSolved.toString(),
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        icon: Icons.check_circle,
                        label: 'Correct Answers',
                        value: totalCorrect.toString(),
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        icon: Icons.local_fire_department,
                        label: 'Current Streak',
                        value: '$currentStreak days',
                        color: Colors.red,
                      ),
                      _buildStatCard(
                        icon: Icons.percent,
                        label: 'Accuracy Rate',
                        value: '${accuracyRate.toStringAsFixed(1)}%',
                        color: Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Settings Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings & Preferences',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Settings Cards
                      _buildSettingCard(
                        icon: Icons.person_outline,
                        title: 'Edit Profile',
                        subtitle: 'Update your profile information',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✨ Edit Profile coming soon'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildSettingCard(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage notification preferences',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔔 Notification settings coming soon'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildSettingCard(
                        icon: Icons.security_outlined,
                        title: 'Privacy & Security',
                        subtitle: 'Manage your security settings',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔐 Privacy settings coming soon'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildSettingCard(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help and contact support',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('💬 Help center coming soon'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildSettingCard(
                        icon: Icons.info_outline,
                        title: 'About FocusTalk',
                        subtitle: 'Version 1.0.0 • Build 2026',
                        onTap: () {
                          _showAboutDialog();
                        },
                      ),
                      const SizedBox(height: 20),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade500,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build statistics card
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build settings card with icon and title
  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.orange.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show about dialog
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About FocusTalk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FocusTalk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal focus assistant powered by English quizzes.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Version: 1.0.0'),
            const Text('Build: 2026'),
            const SizedBox(height: 16),
            Text(
              '© 2026 FocusTalk. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
