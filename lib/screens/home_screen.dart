import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focustalk_app/services/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    print('═══════════════════════════════════════════════════════');
    print('🏠 HOME SCREEN INITIALIZED - initState() called');
    print('═══════════════════════════════════════════════════════');
    _checkServiceStatus();
  }

  /// Check if background service is running
  Future<void> _checkServiceStatus() async {
    print('🔍 Checking background service status...');
    bool isRunning = await FlutterBackgroundService().isRunning();
    print('📊 Service isRunning result: $isRunning');
    if (mounted) {
      setState(() {
        _isServiceRunning = isRunning;
      });
      print('✅ State updated: _isServiceRunning = $_isServiceRunning');
    } else {
      print('⚠️ Widget not mounted, skipping state update');
    }
  }

  /// Toggle protection ON/OFF
  Future<void> _onToggleProtection(bool value) async {
    debugPrint('🔄🔄🔄 Service Triggered: $value 🔄🔄🔄');
    print('🔄 Toggle requested: $value');
    final service = FlutterBackgroundService();

    if (value) {
      // USER WANTS ON
      debugPrint('▶️ Calling service.startService()...');
      await service.startService();
      debugPrint('✅ service.startService() completed');
      print('✅ Command: START Service');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Protection Active'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // USER WANTS OFF
      debugPrint('⏹️ Calling service.invoke("stopService")...');
      service.invoke('stopService');
      debugPrint('✅ service.invoke("stopService") completed');
      print('🛑 Command: STOP Service');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 Protection Stopped'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    // Update UI immediately
    setState(() {
      _isServiceRunning = value;
    });

    debugPrint('📊 UI State updated: _isServiceRunning = $_isServiceRunning');
  }

  /// Toggle app blocking status
  Future<void> _toggleAppStatus(String packageName, bool currentStatus) async {
    try {
      final newStatus = !currentStatus;
      await _dbHelper.toggleAppStatus(packageName, newStatus);

      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? '✅ Monitoring enabled' : '🔓 Monitoring disabled',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling app status: $e');
    }
  }

  /// Get icon based on category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'GAME':
        return Icons.videogame_asset;
      case 'SOCIAL':
        return Icons.chat_bubble;
      case 'PRODUCTIVITY':
        return Icons.work;
      default:
        return Icons.android;
    }
  }

  /// Get color based on category
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'GAME':
        return Colors.deepPurple;
      case 'SOCIAL':
        return Colors.blue;
      case 'PRODUCTIVITY':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================== HEADER SECTION ====================
                    _buildHeader(),

                    const SizedBox(height: 20),

                    // ==================== SUMMARY STATS CARDS ====================
                    _buildStatsCards(),

                    const SizedBox(height: 24),

                    // ==================== PROTECTION STATUS CARD ====================
                    _buildProtectionStatusCard(),

                    const SizedBox(height: 24),

                    // ==================== MONITORED APPS SECTION ====================
                    _buildMonitoredAppsSection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ==================== BOTTOM STATUS BANNER ====================
            if (!_isServiceRunning) _buildBottomStatusBanner(),
          ],
        ),
      ),
    );
  }

  /// Header with blue gradient background
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Profile Icon and Notification Bell
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Arsyandi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: Colors.white,
                iconSize: 28,
                onPressed: () {
                  // TODO: Notification action
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Greeting Text
          const Text(
            'Good Afternoon!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stay focused and productive',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Summary stats cards (3 cards in a row)
  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getAllApps(),
        builder: (context, snapshot) {
          final appsCount = snapshot.hasData ? snapshot.data!.length : 0;

          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.apps,
                  value: appsCount.toString(),
                  label: 'Apps Monitored',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  value: '0h 0m',
                  label: 'Focus Time',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.quiz,
                  value: '0',
                  label: 'Quizzes',
                  color: Colors.orange,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Individual stat card
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
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
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Protection Status Card with Toggle Switch
  Widget _buildProtectionStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    _isServiceRunning
                        ? Colors.green.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isServiceRunning ? Icons.shield : Icons.shield_outlined,
                color: _isServiceRunning ? Colors.green : Colors.grey,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Status Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Protection Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isServiceRunning
                        ? 'ACTIVE - Monitoring is running'
                        : 'INACTIVE - Turn on protection',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Switch Toggle
            Switch(
              value: _isServiceRunning,
              onChanged: _onToggleProtection,
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Status Banner - Shows warning when service is stopped
  Widget _buildBottomStatusBanner() {
    // Only show warning when service is stopped
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(
          top: BorderSide(color: Colors.orange.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Protection Stopped - Turn on to start monitoring',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Monitored Apps Section
  Widget _buildMonitoredAppsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monitored Apps',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {}); // Refresh list
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Apps List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _dbHelper.getAllApps(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Error loading apps: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final apps = snapshot.data ?? [];

              if (apps.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No apps found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: apps.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final app = apps[index];
                  final packageName = app['package_name'] as String;
                  final category = app['category'] as String;
                  final isActive = (app['is_active'] as int? ?? 1) == 1;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _getCategoryColor(
                          category,
                        ).withOpacity(0.15),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: _getCategoryColor(category),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        packageName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: _getCategoryColor(category),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      trailing: Switch(
                        value: isActive,
                        onChanged: (value) {
                          _toggleAppStatus(packageName, isActive);
                        },
                        activeColor: _getCategoryColor(category),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
