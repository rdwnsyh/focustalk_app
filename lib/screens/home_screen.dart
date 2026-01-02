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

                    const SizedBox(height: 16),

                    // Quick Actions Grid
                    _buildQuickActionsGrid(),

                    const SizedBox(height: 16),

                    // Streak Card
                    _buildStreakCard(),

                    const SizedBox(height: 16),

                    // Top Apps Today
                    _buildTopAppsToday(),

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

  /// Header with orange gradient background
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orangeAccent, Colors.deepOrange],
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
          // Top Row: Avatar + Greeting and Notification Bell
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Good Afternoon, Arsyandi!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Stay focused and productive',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
        ],
      ),
    );
  }

  /// Streak card with gradient and 7-day indicators
  Widget _buildStreakCard() {
    final completed = [true, true, true, true, true, false, false];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.redAccent, Colors.deepOrangeAccent]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text('7 Days  ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Keep it up! 🔥', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
                const Text('Streak', style: TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final done = completed[i];
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: done ? Colors.white : Colors.white24,
                      child: done ? Icon(Icons.check, size: 16, color: Colors.deepOrange) : Text(labels[i], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    Text(labels[i], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Apps Today list
  Widget _buildTopAppsToday() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Apps Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _dbHelper.getAllApps(),
            builder: (context, snapshot) {
              final apps = snapshot.data ?? [
                {'package_name': 'Instagram', 'category': 'SOCIAL', 'usage': '45m', 'blocked': 0},
                {'package_name': 'YouTube', 'category': 'ENTERTAINMENT', 'usage': '1h 12m', 'blocked': 5},
                {'package_name': 'Slack', 'category': 'PRODUCTIVITY', 'usage': '30m', 'blocked': 0},
              ];

              return Column(
                children: apps.take(3).map((app) {
                  final pkg = app['package_name'] as String;
                  final category = app['category'] as String;
                  final usage = app['usage'] ?? '';
                  final blocked = app['blocked'] ?? 0;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: _getCategoryColor(category).withOpacity(0.15),
                          child: Icon(_getCategoryIcon(category), color: _getCategoryColor(category)),
                        ),
                        title: Text(pkg, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(category, style: TextStyle(color: Colors.grey[600])),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(blocked > 0 ? 'Blocked ${blocked}x' : (usage ?? ''), style: TextStyle(color: blocked > 0 ? Colors.red : Colors.black87, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: LinearProgressIndicator(value: blocked > 0 ? 0.2 : 0.6, color: _getCategoryColor(category), backgroundColor: _getCategoryColor(category).withOpacity(0.12), minHeight: 6),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Summary stats cards (3 cards in a row)
  Widget _buildStatsCards() {
    // Floating white card that slightly overlaps the header
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dbHelper.getAllApps(),
        builder: (context, snapshot) {
          final appsCount = snapshot.hasData ? snapshot.data!.length : 12;

          return Container(
            transform: Matrix4.translationValues(0, -40, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('12',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700])),
                          const SizedBox(height: 6),
                          Text('Apps Blocked', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('4h 23m',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700])),
                          const SizedBox(height: 6),
                          Text('Focus Time', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('8',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700])),
                          const SizedBox(height: 6),
                          Text('Quizzes', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Goal Progress', style: TextStyle(fontSize: 12, color: Colors.black87)),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: 0.7,
                            color: Colors.blue,
                            backgroundColor: Colors.blue.shade50,
                            minHeight: 8,
                          ),
                          const SizedBox(height: 6),
                          Text('Goal: 6 hours', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

  /// Quick Actions 2x2 grid
  Widget _buildQuickActionsGrid() {
    final items = [
      {'label': 'Blocked Apps', 'icon': Icons.block, 'color': Colors.red},
      {'label': 'Allowed Apps', 'icon': Icons.check_circle, 'color': Colors.green},
      {'label': 'Practice Quiz', 'icon': Icons.quiz, 'color': Colors.blue},
      {'label': 'Settings', 'icon': Icons.settings, 'color': Colors.grey},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3,
        children: items.map((it) {
          return GestureDetector(
            onTap: () {
              // TODO: wire up actions
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0,4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (it['color'] as Color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(it['icon'] as IconData, color: it['color'] as Color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      it['label'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
