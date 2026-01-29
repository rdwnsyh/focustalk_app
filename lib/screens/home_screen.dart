import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/screens/leaderboard_screen.dart';
import 'package:focustalk_app/screens/settings_screen.dart';

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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // SECTION A: Header with Orange Gradient
              _buildHeader(),

              const SizedBox(height: 20),

              // SECTION B: Focus & Goal Card (Hybrid with Slider Logic)
              _buildFocusAndGoalCard(),

              const SizedBox(height: 24),

              // SECTION C: Protection Toggle
              _buildProtectionStatusCard(),

              const SizedBox(height: 24),

              // SECTION D: Quick Actions Grid
              _buildQuickActionsGrid(),

              const SizedBox(height: 24),

              // SECTION E: Streak Card
              _buildStreakCard(),

              const SizedBox(height: 24),

              // SECTION F: Top Apps List
              _buildTopAppsList(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// SECTION A: Header with Orange Gradient
  Widget _buildHeader() {
    // Determine greeting based on time
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17) {
      greeting = 'Good Evening';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFFF5E62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Row(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          // Greeting Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Trophy/Notification Icon Button
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaderboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// SECTION B: Focus & Goal Card (Hybrid with Daily Goal Slider Logic)
  Widget _buildFocusAndGoalCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _getDailyGoalData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final data = snapshot.data!;
          final dailyGoal = data['goal'] as int;
          final solvedToday = data['solved'] as int;
          final progress = data['progress'] as double;
          final remaining = dailyGoal - solvedToday;

          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Part 1: Stats Row (Apps Blocked, Focus Time, Quizzes)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem('Apps Blocked', _monitoredAppsCount.toString(), Colors.blue),
                      _buildStatItem('Focus Time', '0h 0m', Colors.green),
                      _buildStatItem('Quizzes', _solvedToday.toString(), Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Part 2: Divider
                  Divider(color: Colors.grey[300], thickness: 1),
                  const SizedBox(height: 16),

                  // Part 3: Daily Goal Integration
                  // Goal Text Row with big blue numbers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily Goal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '$solvedToday/$dailyGoal',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: dailyGoal > 0 ? (solvedToday / dailyGoal).clamp(0.0, 1.0) : 0.0,
                      minHeight: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Motivation Text
                  Text(
                    remaining > 0
                        ? 'Keep going! $remaining question${remaining > 1 ? 's' : ''} left'
                        : '🎉 Goal Reached!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: remaining > 0 ? Colors.grey[700] : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // The Slider for Daily Target
                  Row(
                    children: [
                      const Text(
                        'Daily Target:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: dailyGoal.toDouble(),
                          min: 5,
                          max: 50,
                          divisions: 9,
                          label: '$dailyGoal',
                          onChanged: (value) async {
                            await _dbHelper.setDailyGoal(value.toInt());
                            setState(() {});
                          },
                          activeColor: Colors.blue,
                        ),
                      ),
                      Text(
                        '$dailyGoal',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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

  /// Helper: Build individual stat item
  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
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

  /// SECTION D: Quick Actions Grid (2x2)
  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildQuickActionCard(
                icon: Icons.apps,
                label: 'Blocked Apps',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Blocked Apps...')),
                ),
              ),
              _buildQuickActionCard(
                icon: Icons.done_all,
                label: 'Allowed Apps',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Allowed Apps...')),
                ),
              ),
              _buildQuickActionCard(
                icon: Icons.quiz,
                label: 'Practice Quiz',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting Quiz...')),
                ),
              ),
              _buildQuickActionCard(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper: Build quick action card
  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SECTION E: Streak Card
  Widget _buildStreakCard() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final activeDays = [true, true, true, false, true, false, false];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Streak Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🔥',
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 12),
                Text(
                  '0 Days Streak',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 7-Day Checkboxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                7,
                (index) => Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeDays[index]
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.15),
                        border: Border.all(
                          color: activeDays[index]
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          activeDays[index] ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// SECTION F: Top Apps / Recent Activity
  Widget _buildTopAppsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Apps Today',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                final appNames = ['Facebook', 'YouTube', 'Twitter', 'Games', 'Shopping'];
                final appIcons = [
                  Icons.facebook,
                  Icons.videocam,
                  Icons.public,
                  Icons.games,
                  Icons.shopping_cart,
                ];
                final durations = ['2h 30m', '1h 45m', '45m', '30m', '15m'];
                final priorities = ['High', 'High', 'Medium', 'Low', 'Low'];
                final priorityColors = [
                  Colors.red.shade100,
                  Colors.red.shade100,
                  Colors.orange.shade100,
                  Colors.green.shade100,
                  Colors.green.shade100,
                ];
                final priorityTextColors = [
                  Colors.red.shade700,
                  Colors.red.shade700,
                  Colors.orange.shade700,
                  Colors.green.shade700,
                  Colors.green.shade700,
                ];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.withOpacity(0.2),
                    child: Icon(
                      appIcons[index],
                      color: Colors.deepPurple,
                    ),
                  ),
                  title: Text(
                    appNames[index],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    durations[index],
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  trailing: Chip(
                    label: Text(
                      priorities[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: priorityColors[index],
                    labelStyle: TextStyle(
                      color: priorityTextColors[index],
                    ),
                  ),
                );
              },
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
