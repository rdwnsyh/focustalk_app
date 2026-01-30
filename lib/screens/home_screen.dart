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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isServiceRunning = false;

  // Live dashboard data
  int _solvedToday = 0;
  int _monitoredAppsCount = 0;
  int _dailyGoal = 5;
  String _focusTime = '0h 0m';
  Timer? _refreshTimer;
  late AnimationController _animationController;

  // Streak
  int _streakCount = 0;
  List<bool> _weeklyStreak = List.filled(7, false);
  DateTime? _lastStreakDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
    
    print('═══════════════════════════════════════════════════════');
    print('🏠 HOME SCREEN INITIALIZED - initState() called');
    print('═══════════════════════════════════════════════════════');
    _checkServiceStatus();
    _loadDashboardData(); // Initial load
    _loadStreakData();

    // Auto-refresh every 3 seconds (background service updates data)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel(); // Stop timer when screen is disposed
    _animationController.dispose();
    super.dispose();
  }

  /// Load dashboard data from SharedPreferences
  Future<void> _loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Force reload from disk

      final solved = prefs.getInt('solved_today') ?? 0;
      final goal = prefs.getInt('daily_goal') ?? 5;
      
      // Get focus time in minutes from SharedPreferences or database
      final focusMinutes = prefs.getInt('focus_time_today') ?? 0;
      final hours = focusMinutes ~/ 60;
      final minutes = focusMinutes % 60;
      final focusTimeStr = '${hours}h ${minutes}m';

      // Get apps count for stats card
      final apps = await _dbHelper.getAllApps();
      final appsCount = apps.length;

      if (mounted) {
        setState(() {
          _solvedToday = solved;
          _dailyGoal = goal;
          _monitoredAppsCount = appsCount;
          _focusTime = focusTimeStr;
        });
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
    }
  }

  // Load Streak Data
  Future<void> _loadStreakData() async {
  final prefs = await SharedPreferences.getInstance();

  final streak = prefs.getInt('streak_count') ?? 0;
  final lastDateStr = prefs.getString('last_streak_date');
  final weeklyStr = prefs.getString('weekly_streak');

  DateTime? lastDate;
  if (lastDateStr != null) {
    lastDate = DateTime.parse(lastDateStr);
  }

  List<bool> weekly = List.filled(7, false);
  if (weeklyStr != null) {
    weekly = List<bool>.from(jsonDecode(weeklyStr));
  }

  setState(() {
    _streakCount = streak;
    _lastStreakDate = lastDate;
    _weeklyStreak = weekly;
  });
}

// ini dipanggil setelah overlay quiz selesai lalu claim streak
Future<void> claimStreak() async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (_lastStreakDate != null) {
    final last = DateTime(
      _lastStreakDate!.year,
      _lastStreakDate!.month,
      _lastStreakDate!.day,
    );

    // Sudah klaim hari ini
    if (last == today) return;

    // Lanjut streak
    if (today.difference(last).inDays == 1) {
      _streakCount++;
    } else {
      // Bolong → reset
      _streakCount = 1;
      _weeklyStreak = List.filled(7, false);
    }
  } else {
    _streakCount = 1;
  }

  // Tandai hari ini
  final weekdayIndex = today.weekday - 1; // Mon = 0
  _weeklyStreak[weekdayIndex] = true;

  _lastStreakDate = today;

  await prefs.setInt('streak_count', _streakCount);
  await prefs.setString('last_streak_date', today.toIso8601String());
  await prefs.setString('weekly_streak', jsonEncode(_weeklyStreak));

  setState(() {});
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Protection Active'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text('🛑 Protection Stopped'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
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
      backgroundColor: const Color(0xFFFFF5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // SECTION A: Header with Orange Gradient
              _buildHeader(),

              const SizedBox(height: 20),

              // SECTION B: Focus & Goal Card (Hybrid with Slider Logic)
              _buildFocusAndGoalCard(),

              const SizedBox(height: 20),

              // SECTION C: Protection Toggle
              _buildProtectionStatusCard(),

              const SizedBox(height: 20),

              // SECTION D: Quick Actions Grid
              _buildQuickActionsGrid(),

              const SizedBox(height: 20),

              // SECTION E: Streak Card
              _buildStreakCard(),

              const SizedBox(height: 20),

              // SECTION F: Top Apps List
              _buildTopAppsList(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// SECTION A: Header with Orange Gradient - REDESIGNED
  Widget _buildHeader() {
    // Determine greeting based on time
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Night';
    }

  return FadeTransition(
    opacity: _animationController,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF6B35),
            Color(0xFFFF8C42),
            Color(0xFFFFAA64),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF6B35).withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative glow circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // Main Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.6),
                      Colors.white.withOpacity(0.25),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Trophy Button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LeaderboardScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  /// SECTION B: Focus & Goal Card - REDESIGNED
  Widget _buildFocusAndGoalCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _getDailyGoalData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final data = snapshot.data!;
          final dailyGoal = data['goal'] as int;
          final solvedToday = data['solved'] as int;
          final progress = data['progress'] as double;
          final remaining = dailyGoal - solvedToday;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Part 1: Stats Row - Simple layout like the example
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSimpleStatItem('Apps Blocked', _monitoredAppsCount.toString(), 
                        const Color(0xFF2196F3)),
                      _buildSimpleStatItem('Focus Time', _focusTime, 
                        const Color(0xFF4CAF50)),
                      _buildSimpleStatItem('Quizzes', _solvedToday.toString(), 
                        const Color(0xFFFF9800)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Elegant divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey.shade200,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Part 3: Daily Goal Section with modern design
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.flag_rounded, color: Color(0xFFFF6B35), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Daily Goal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '$solvedToday/$dailyGoal',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),

                  // Modern Progress Bar with gradient
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6B35).withOpacity(0.1),
                              const Color(0xFFFFAA64).withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: dailyGoal > 0 ? (solvedToday / dailyGoal).clamp(0.0, 1.0) : 0.0,
                          minHeight: 12,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),

                  // Motivation Badge with icon
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: remaining > 0
                            ? [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)]
                            : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: remaining > 0
                            ? const Color(0xFFFFAA64)
                            : const Color(0xFF81C784),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          remaining > 0 ? '💪' : '🎉',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            remaining > 0
                                ? 'Keep going! $remaining question${remaining > 1 ? 's' : ''} left'
                                : 'Goal Reached! Amazing work!',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: remaining > 0
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Modern Slider with better styling
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Target',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$dailyGoal',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 6,
                          activeTrackColor: const Color(0xFFFF6B35),
                          inactiveTrackColor: const Color(0xFFFF6B35).withOpacity(0.2),
                          thumbColor: const Color(0xFFFF6B35),
                          overlayColor: const Color(0xFFFF6B35).withOpacity(0.2),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 4,
                          ),
                        ),
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
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '5',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            Text(
                              '50',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
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

  /// Helper: Build simple stat item like the example
  Widget _buildSimpleStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: Build modern stat item with icon
  Widget _buildModernStatItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Protection Status Card - REDESIGNED
  Widget _buildProtectionStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _onToggleProtection(!_isServiceRunning),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: _isServiceRunning
                ? const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isServiceRunning
                  ? Colors.transparent
                  : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isServiceRunning
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Animated Icon Container
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isServiceRunning
                      ? Colors.white.withOpacity(0.25)
                      : const Color.fromARGB(255, 129, 129, 129).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (_isServiceRunning)
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Icon(
                  _isServiceRunning ? Icons.shield_rounded : Icons.shield_outlined,
                  color: _isServiceRunning ? Colors.white : const Color(0xFFFF6B35),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Status Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Protection Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isServiceRunning ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isServiceRunning
                          ? 'ACTIVE - You are protected'
                          : 'INACTIVE - Tap to activate',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _isServiceRunning
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Modern Toggle Switch
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: _isServiceRunning
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey.shade300,
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: _isServiceRunning ? 26 : 2,
                      top: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SECTION D: Quick Actions Grid - REDESIGNED
  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildModernQuickActionCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                icon: Icons.apps_rounded,
                label: 'Blocked Apps',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  _buildModernSnackBar('Opening Blocked Apps...'),
                ),
              ),
              _buildModernQuickActionCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                icon: Icons.done_all_rounded,
                label: 'Allowed Apps',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  _buildModernSnackBar('Opening Allowed Apps...'),
                ),
              ),
              _buildModernQuickActionCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                icon: Icons.quiz_rounded,
                label: 'Practice Quiz',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  _buildModernSnackBar('Starting Quiz...'),
                ),
              ),
              _buildModernQuickActionCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                icon: Icons.settings_rounded,
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

  /// Helper: Build modern quick action card
  Widget _buildModernQuickActionCard({
    required Gradient gradient,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Build modern snackbar
  SnackBar _buildModernSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF1F2937),
    );
  }

  /// SECTION E: Streak Card - REDESIGNED
Widget _buildStreakCard() {
  final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42), Color(0xFFFFAA64)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Text(
                  '$_streakCount Days Streak',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Weekly Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final active = _weeklyStreak[index];

              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      active ? Icons.check_rounded : Icons.lock_outline,
                      color: active
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    days[index],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    ),
  );
}

  /// SECTION F: Top Apps List - REDESIGNED
  Widget _buildTopAppsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Top Apps Today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey.shade200,
                height: 1,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final appNames = ['Facebook', 'YouTube', 'Twitter', 'Games', 'Shopping'];
                final appIcons = [
                  Icons.facebook_rounded,
                  Icons.videocam_rounded,
                  Icons.public_rounded,
                  Icons.games_rounded,
                  Icons.shopping_cart_rounded,
                ];
                final durations = ['2h 30m', '1h 45m', '45m', '30m', '15m'];
                final priorities = ['High', 'High', 'Medium', 'Low', 'Low'];
                final priorityColors = [
                  const Color(0xFFEF4444),
                  const Color(0xFFEF4444),
                  const Color(0xFFF59E0B),
                  const Color(0xFF10B981),
                  const Color(0xFF10B981),
                ];

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // App Icon with gradient
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF8B5CF6).withOpacity(0.8),
                              const Color(0xFF7C3AED),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          appIcons[index],
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // App Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appNames[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              durations[index],
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: priorityColors[index].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: priorityColors[index].withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          priorities[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: priorityColors[index],
                          ),
                        ),
                      ),
                    ],
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