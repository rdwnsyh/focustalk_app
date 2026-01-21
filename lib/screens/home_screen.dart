import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isServiceRunning = false;

  // Live dashboard data
  int _solvedToday = 0;
  int _monitoredAppsCount = 0;
  int _dailyGoal = 5;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    print('═══════════════════════════════════════════════════════');
    print('🏠 HOME SCREEN INITIALIZED - initState() called');
    print('═══════════════════════════════════════════════════════');
    _checkServiceStatus();
    _loadDashboardData(); // Initial load

    // Auto-refresh every 3 seconds (background service updates data)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Stop timer when screen is disposed
    super.dispose();
  }

  /// Load dashboard data from SharedPreferences
  Future<void> _loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force reload from disk

      final solved = prefs.getInt('solved_today') ?? 0;
      final goal = prefs.getInt('daily_goal') ?? 5;

      // Get apps count for stats card
      final apps = await _dbHelper.getAllApps();
      final appsCount = apps.length;

      if (mounted) {
        setState(() {
          _solvedToday = solved;
          _dailyGoal = goal;
          _monitoredAppsCount = appsCount;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
    }
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

                    // ==================== DAILY GOAL PROGRESS ====================
                    _buildDailyGoalCard(),

                    const SizedBox(height: 20),

                    // ==================== SUMMARY STATS CARDS ====================
                    _buildStatsCards(),

                    const SizedBox(height: 24),

                    // ==================== PROTECTION STATUS CARD ====================
                    _buildProtectionStatusCard(),

                    const SizedBox(height: 24),
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
          // Top Row: Profile Icon
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
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.apps,
              value: _monitoredAppsCount.toString(),
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
              value: _solvedToday.toString(),
              label: 'Quizzes',
              color: Colors.orange,
            ),
          ),
        ],
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

  /// Daily Goal Progress Card
  Widget _buildDailyGoalCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _getDailyGoalData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final data = snapshot.data!;
          final dailyGoal = data['goal'] as int;
          final solvedToday = data['solved'] as int;
          final progress = data['progress'] as double;
          final isGoalMet = solvedToday >= dailyGoal;

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isGoalMet
                                ? Icons.check_circle
                                : Icons.track_changes,
                            color: isGoalMet ? Colors.green : Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Daily Goal',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$solvedToday/$dailyGoal',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isGoalMet ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isGoalMet ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isGoalMet ? Colors.green[50] : Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isGoalMet
                                ? Colors.green[200]!
                                : Colors.orange[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isGoalMet ? Icons.celebration : Icons.psychology,
                          color:
                              isGoalMet
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isGoalMet
                                ? '🎉 Target Reached! You are free today!'
                                : '💪 Keep going! ${dailyGoal - solvedToday} question${dailyGoal - solvedToday > 1 ? 's' : ''} left',
                            style: TextStyle(
                              color:
                                  isGoalMet
                                      ? Colors.green[900]
                                      : Colors.orange[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Daily Goal Slider
                  Row(
                    children: [
                      const Text(
                        'Daily Target:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: dailyGoal.toDouble(),
                          min: 5,
                          max: 50,
                          divisions: 9,
                          label: '$dailyGoal questions',
                          onChanged: (value) async {
                            await _dbHelper.setDailyGoal(value.toInt());
                            setState(() {}); // Refresh UI
                          },
                        ),
                      ),
                      Text(
                        '$dailyGoal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Get daily goal data
  Future<Map<String, dynamic>> _getDailyGoalData() async {
    final goal = await _dbHelper.getDailyGoal();
    final solved = await _dbHelper.getSolvedToday();
    final progress = await _dbHelper.getProgressPercentage();

    return {'goal': goal, 'solved': solved, 'progress': progress};
  }
}
