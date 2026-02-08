import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/screens/leaderboard_screen.dart';
import 'package:focustalk_app/screens/settings_screen.dart';
import 'package:focustalk_app/screens/apps_screen.dart';
import 'package:focustalk_app/screens/practice_quiz_screen.dart';
import 'package:focustalk_app/screens/material_screen.dart';
import 'package:get/get.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

// Model to hold app usage data with icon
class AppUsageWithIcon {
  final AppUsageInfo usageInfo;
  final AppInfo? appInfo;

  AppUsageWithIcon(this.usageInfo, this.appInfo);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isServiceRunning = false;

  // Live dashboard data
  int _solvedToday = 0;
  int _monitoredAppsCount = 0;
  int _dailyGoal = 5;
  String _focusTime = '0h 0m';
  String _username = 'User'; // Dynamic username
  Timer? _refreshTimer;
  late AnimationController _animationController;

  // Streak
  int _streakCount = 0;
  List<bool> _weeklyStreak = List.filled(7, false);
  DateTime? _lastStreakDate;

  // Top Apps Data
  Future<List<AppUsageWithIcon>>? _topAppsFuture;

  // Notifications
  List<Map<String, dynamic>> _notifications = [];

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
    _topAppsFuture = _fetchTopApps(); // Fetch top apps once
    _checkDailyReminders(); // Check and update notifications
    _checkDailyReminders(); // Check and update notifications

    // Auto-refresh every 3 seconds (background service updates data)
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadDashboardData();
      _loadStreakData(); // Also refresh streak data
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

      // Get username from SharedPreferences
      final userName = prefs.getString('user_name') ?? 'User';

      if (mounted) {
        setState(() {
          _solvedToday = solved;
          _dailyGoal = goal;
          _monitoredAppsCount = appsCount;
          _focusTime = focusTimeStr;
          _username = userName;
        });

        // Automatically claim streak when daily goal is met
        if (solved >= goal) {
          await claimStreak();
        }

        _checkDailyReminders(); // Update notifications after loading data
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
    final lastWeekStartStr = prefs.getString('last_week_start');

    DateTime? lastDate;
    if (lastDateStr != null) {
      lastDate = DateTime.parse(lastDateStr);
    }

    List<bool> weekly = List.filled(7, false);
    if (weeklyStr != null) {
      weekly = List<bool>.from(jsonDecode(weeklyStr));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if we're in a new week (Monday = start of week)
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    DateTime? lastWeekStart;
    if (lastWeekStartStr != null) {
      lastWeekStart = DateTime.parse(lastWeekStartStr);
    }

    // If it's a new week, reset the weekly tracking
    if (lastWeekStart != null && currentWeekStart.isAfter(lastWeekStart)) {
      print('📅 New week detected! Resetting weekly streak display...');
      weekly = List.filled(7, false);
      await prefs.setString('weekly_streak', jsonEncode(weekly));
    }

    // Save current week start
    if (lastWeekStart == null || currentWeekStart.isAfter(lastWeekStart)) {
      await prefs.setString(
        'last_week_start',
        currentWeekStart.toIso8601String(),
      );
    }

    // AUTOMATIC STREAK VALIDATION: Check if streak should be broken
    if (lastDate != null) {
      final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final daysDifference = today.difference(last).inDays;

      // If more than 1 day has passed without activity, reset streak
      if (daysDifference > 1) {
        print(
          '⚠️ Streak broken! Last activity was $daysDifference days ago. Resetting...',
        );
        await prefs.setInt('streak_count', 0);
        await prefs.setString(
          'weekly_streak',
          jsonEncode(List.filled(7, false)),
        );

        setState(() {
          _streakCount = 0;
          _lastStreakDate = lastDate;
          _weeklyStreak = List.filled(7, false);
        });
        return;
      }
    }

    setState(() {
      _streakCount = streak;
      _lastStreakDate = lastDate;
      _weeklyStreak = weekly;

      // Ensure today is marked if lastDate is today
      if (lastDate != null) {
        final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
        if (last == today && streak > 0) {
          final todayIndex = today.weekday - 1; // Mon = 0, Sun = 6
          if (!_weeklyStreak[todayIndex]) {
            _weeklyStreak[todayIndex] = true;
            print(
              '🔄 Marking today (index $todayIndex) as complete in display',
            );
          }
        }
      }
    });

    print(
      '📊 Streak loaded - Count: $_streakCount, Weekly: $_weeklyStreak, Today: ${today.weekday}',
    );
  }

  // ini dipanggil setelah overlay quiz selesai lalu claim streak
  Future<void> claimStreak() async {
    print('🎯 claimStreak() called');
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    print(
      '📅 Today: $today, Weekday: ${today.weekday} (${today.weekday - 1} index)',
    );

    if (_lastStreakDate != null) {
      final last = DateTime(
        _lastStreakDate!.year,
        _lastStreakDate!.month,
        _lastStreakDate!.day,
      );

      print('🔍 Last streak date: $last');

      // Sudah klaim hari ini
      if (last == today) {
        print('⚠️ Already claimed today, skipping');
        return;
      }

      // Lanjut streak
      if (today.difference(last).inDays == 1) {
        _streakCount++;
        print('✅ Continuing streak! New count: $_streakCount');
        // Keep existing weekly data, just add today
      } else if (today.difference(last).inDays > 1) {
        // Streak broken - reset everything
        print('💔 Streak broken! Resetting to 1');
        _streakCount = 1;
        _weeklyStreak = List.filled(7, false);
      }
    } else {
      // First time claiming
      print('🆕 First time claiming streak');
      _streakCount = 1;
      _weeklyStreak = List.filled(7, false);
    }

    // Tandai hari ini
    final weekdayIndex = today.weekday - 1; // Mon = 0, Sun = 6
    print(
      '📍 Marking weekday index: $weekdayIndex (${['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekdayIndex]})',
    );
    _weeklyStreak[weekdayIndex] = true;

    _lastStreakDate = today;

    await prefs.setInt('streak_count', _streakCount);
    await prefs.setString('last_streak_date', today.toIso8601String());
    await prefs.setString('weekly_streak', jsonEncode(_weeklyStreak));

    print(
      '✅ Streak claimed! Count: $_streakCount, Today: ${today.weekday}, Weekly: $_weeklyStreak',
    );

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  /// Helper method to check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check and update daily quiz reminders
  void _checkDailyReminders() {
    setState(() {
      // Get current time for Streak Saver logic
      final now = DateTime.now();
      final currentHour = now.hour;

      if (_solvedToday < _dailyGoal) {
        // User hasn't completed daily goal
        final remaining = _dailyGoal - _solvedToday;

        // ⚡ STREAK SAVER LOGIC: Critical notification after 7 PM
        if (currentHour >= 19) {
          // Check if critical notification already exists for today
          bool criticalExists = _notifications.any(
            (n) => n['type'] == 'critical' && _isSameDay(n['timestamp'], now),
          );

          if (!criticalExists) {
            // After 7 PM - Show URGENT streak warning
            _notifications.add({
              'title': '🔥 Streak Danger!',
              'message':
                  "You are about to lose your $_streakCount day streak! Answer $remaining more question${remaining > 1 ? 's' : ''} to save it.",
              'type': 'critical',
              'icon': Icons.local_fire_department,
              'color': const Color(0xFFDC2626), // Red
              'timestamp': DateTime.now(),
            });
          }
        }

        // Check if warning notification already exists for today
        bool warningExists = _notifications.any(
          (n) => n['type'] == 'warning' && _isSameDay(n['timestamp'], now),
        );

        if (!warningExists) {
          // Regular reminder notification
          _notifications.add({
            'title': 'Daily Quiz Reminder',
            'message':
                "You haven't finished your goal yet! $remaining question${remaining > 1 ? 's' : ''} left to reach your streak.",
            'type': 'warning',
            'icon': Icons.access_time_filled,
            'color': Colors.orange,
            'timestamp': DateTime.now(),
          });
        }
      } else {
        // Check if success notification already exists for today
        bool successExists = _notifications.any(
          (n) => n['type'] == 'success' && _isSameDay(n['timestamp'], now),
        );

        if (!successExists) {
          // User completed daily goal
          _notifications.add({
            'title': 'Goal Achieved! 🎉',
            'message': "Great job! You've completed your daily target.",
            'type': 'success',
            'icon': Icons.check_circle,
            'color': Colors.green,
            'timestamp': DateTime.now(),
          });
        }
      }
    });
  }

  /// Format timestamp to readable time (HH:mm format)
  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Show notification bottom sheet
  void _openNotificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Notifications List
                if (_notifications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No notifications yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isCritical = notification['type'] == 'critical';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (notification['color'] as Color).withOpacity(
                            isCritical
                                ? 0.15
                                : 0.1, // Stronger background for critical
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (notification['color'] as Color).withOpacity(
                              isCritical
                                  ? 0.5
                                  : 0.3, // Stronger border for critical
                            ),
                            width:
                                isCritical
                                    ? 2
                                    : 1, // Thicker border for critical
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: notification['color'] as Color,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow:
                                    isCritical
                                        ? [
                                          BoxShadow(
                                            color: (notification['color']
                                                    as Color)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                        : null, // Add glow effect for critical
                              ),
                              child: Icon(
                                notification['icon'] as IconData,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification['title'] as String,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                isCritical
                                                    ? const Color(
                                                      0xFFDC2626,
                                                    ) // Red for critical
                                                    : const Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatTimestamp(
                                          notification['timestamp'] as DateTime,
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              isCritical
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color:
                                              isCritical
                                                  ? const Color(0xFFDC2626)
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['message'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          isCritical
                                              ? const Color(
                                                0xFF991B1B,
                                              ) // Dark red for critical
                                              : Colors.grey[700],
                                      height: 1.4,
                                      fontWeight:
                                          isCritical
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
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
    // Determine greeting based on time of day
    final hour = DateTime.now().hour;
    String greeting;

    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Good Afternoon';
    } else if (hour >= 18 && hour < 21) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35),
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
                // Avatar - Reduced size
                Container(
                  padding: const EdgeInsets.all(2),
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
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Action Buttons Row
                Row(
                  children: [
                    // Notification Button - Compact with Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _openNotificationSheet,
                          ),
                        ),
                        // Red Dot Indicator (only if goal not met)
                        if (_solvedToday < _dailyGoal)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Trophy/Leaderboard Button - Compact
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 22,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Part 1: Stats Row - Modern Card Design with Icons
                  Row(
                    children: [
                      _buildModernStatCard(
                        'Apps Blocked',
                        _monitoredAppsCount.toString(),
                        Icons.lock_rounded,
                        const Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 10),
                      _buildModernStatCard(
                        'Focus Time',
                        _focusTime,
                        Icons.access_time_rounded,
                        const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 10),
                      _buildModernStatCard(
                        'Quizzes',
                        _solvedToday.toString(),
                        Icons.quiz_rounded,
                        const Color(0xFFFF9800),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 20),

                  // Part 3: Daily Goal Section with modern design - Compact
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            color: Color(0xFFFF6B35),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Daily Goal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B35).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '$solvedToday/$dailyGoal',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

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
                          value:
                              dailyGoal > 0
                                  ? (solvedToday / dailyGoal).clamp(0.0, 1.0)
                                  : 0.0,
                          minHeight: 12,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Motivation Badge with icon - Compact
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            remaining > 0
                                ? [
                                  const Color(0xFFFFF3E0),
                                  const Color(0xFFFFE0B2),
                                ]
                                : [
                                  const Color(0xFFE8F5E9),
                                  const Color(0xFFC8E6C9),
                                ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            remaining > 0
                                ? const Color(0xFFFFAA64)
                                : const Color(0xFF81C784),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          remaining > 0 ? '💪' : '🎉',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            remaining > 0
                                ? 'Keep going! $remaining question${remaining > 1 ? 's' : ''} left'
                                : 'Goal Reached! Amazing work!',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color:
                                  remaining > 0
                                      ? const Color(0xFFE65100)
                                      : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Modern Slider with better styling - Compact
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Target',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$dailyGoal',
                              style: const TextStyle(
                                fontSize: 16,
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
                          inactiveTrackColor: const Color(
                            0xFFFF6B35,
                          ).withOpacity(0.2),
                          thumbColor: const Color(0xFFFF6B35),
                          overlayColor: const Color(
                            0xFFFF6B35,
                          ).withOpacity(0.2),
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

  /// Helper: Build modern stat card with white background, icon, and shadow
  Widget _buildModernStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Build simple stat item (kept for backward compatibility)
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Helper: Build modern stat item with icon
  Widget _buildModernStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
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
            gradient:
                _isServiceRunning
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
              color:
                  _isServiceRunning ? Colors.transparent : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    _isServiceRunning
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
                  color:
                      _isServiceRunning
                          ? Colors.white.withOpacity(0.25)
                          : const Color.fromARGB(
                            255,
                            129,
                            129,
                            129,
                          ).withOpacity(0.1),
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
                  _isServiceRunning
                      ? Icons.shield_rounded
                      : Icons.shield_outlined,
                  color:
                      _isServiceRunning
                          ? Colors.white
                          : const Color(0xFFFF6B35),
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
                        color:
                            _isServiceRunning
                                ? Colors.white
                                : const Color(0xFF1F2937),
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
                        color:
                            _isServiceRunning
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
                  color:
                      _isServiceRunning
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

  /// SECTION D: Fokus Belajar Grid
  Widget _buildQuickActionsGrid() {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'Materi',
        'icon': Icons.menu_book_rounded,
        'color': Colors.blue,
        'onTap': () => Get.to(() => MaterialView()),
      },
      {
        'title': 'Latihan',
        'icon': Icons.edit_note_rounded,
        'color': Colors.green,
        'onTap': () => Get.to(() => PracticeQuizScreen()),
      },
      {
        'title': 'Ranking',
        'icon': Icons.emoji_events_rounded,
        'color': Colors.orange,
        'onTap': () => Get.to(() => LeaderboardScreen()),
      },
      {
        'title': 'Apps',
        'icon': Icons.block_flipped,
        'color': Colors.red,
        'onTap': () => Get.to(() => AppsScreen()),
      },
      {
        'title': 'Settings',
        'icon': Icons.settings_rounded,
        'color': Colors.grey,
        'onTap': () => Get.to(() => SettingsScreen()),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Fokus Belajar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildFokusBelajarItem(
                  title: item['title'] as String,
                  icon: item['icon'] as IconData,
                  color: item['color'] as Color,
                  onTap: item['onTap'] as VoidCallback,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFokusBelajarItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper: Build action card with semantic colors
  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
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
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      '$_streakCount Days Streak',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
                        color:
                            active
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                        boxShadow:
                            active
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
                        color:
                            active
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

  /// Fetch top 5 apps by usage today with icons
  Future<List<AppUsageWithIcon>> _fetchTopApps() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = now;

      final usage = await AppUsage().getAppUsage(startOfDay, endOfDay);

      // Filter out system apps and sort by usage duration
      final filtered =
          usage.where((app) {
            final packageName = app.packageName.toLowerCase();
            return !packageName.startsWith('com.android') &&
                !packageName.startsWith(
                  'com.google.android.googlequicksearchbox',
                ) &&
                !packageName.startsWith('com.sec.android') &&
                !packageName.startsWith('android') &&
                app.usage.inMinutes > 0;
          }).toList();

      // Sort by duration (descending)
      filtered.sort((a, b) => b.usage.compareTo(a.usage));

      // Take top 5
      final top5 = filtered.take(5).toList();

      // Fetch icons for all apps
      final List<AppUsageWithIcon> appsWithIcons = [];
      for (final app in top5) {
        try {
          final appInfo = await InstalledApps.getAppInfo(app.packageName, null);
          appsWithIcons.add(AppUsageWithIcon(app, appInfo));
        } catch (e) {
          appsWithIcons.add(AppUsageWithIcon(app, null));
        }
      }

      return appsWithIcons;
    } catch (e) {
      print('❌ Error fetching app usage: $e');
      return [];
    }
  }

  /// Helper function to get brand colors based on app name or package name
  Color _getAppBrandColor(String appName, String packageName) {
    final name = appName.toLowerCase();
    final package = packageName.toLowerCase();

    // Check app name first
    if (name.contains('facebook') || package.contains('facebook')) {
      return const Color(0xFF1877F2);
    } else if (name.contains('youtube') || package.contains('youtube')) {
      return const Color(0xFFFF0000);
    } else if (name.contains('whatsapp') || package.contains('whatsapp')) {
      return const Color(0xFF25D366);
    } else if (name.contains('instagram') || package.contains('instagram')) {
      return const Color(0xFFC13584);
    } else if (name.contains('twitter') ||
        name.contains('x') ||
        package.contains('twitter')) {
      return const Color(0xFF1DA1F2);
    } else if (name.contains('tiktok') || package.contains('tiktok')) {
      return const Color(0xFF000000);
    } else if (name.contains('telegram') || package.contains('telegram')) {
      return const Color(0xFF0088CC);
    } else if (name.contains('spotify') || package.contains('spotify')) {
      return const Color(0xFF1DB954);
    } else if (name.contains('netflix') || package.contains('netflix')) {
      return const Color(0xFFE50914);
    } else if (package.contains('mobile.legends') ||
        name.contains('mobile legends')) {
      return const Color(0xFFFFD700); // Gold
    } else if (package.contains('game') || name.contains('game')) {
      return const Color(0xFFFF6B35); // Orange for games
    } else {
      // Default blue for unrecognized apps
      return const Color(0xFF3B82F6);
    }
  }

  /// SECTION F: Top Apps List - WITH REAL DATA
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
            child: FutureBuilder<List<AppUsageWithIcon>>(
              future: _topAppsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.hourglass_empty,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No app usage data today',
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

                final topApps = snapshot.data!;
                final maxDuration =
                    topApps.first.usageInfo.usage.inMinutes.toDouble();

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topApps.length,
                  separatorBuilder:
                      (context, index) => Divider(
                        color: Colors.grey.shade200,
                        height: 1,
                        indent: 72,
                      ),
                  itemBuilder: (context, index) {
                    final appData = topApps[index];
                    final app = appData.usageInfo;
                    final appInfo = appData.appInfo;
                    final duration = app.usage;
                    final hours = duration.inHours;
                    final minutes = duration.inMinutes % 60;

                    // Format duration
                    String durationText;
                    if (hours > 0) {
                      durationText = '${hours}h ${minutes}m';
                    } else {
                      durationText = '${minutes}m';
                    }

                    // Calculate progress (0.0 to 1.0)
                    final progress = duration.inMinutes / maxDuration;

                    // Get app name
                    String appName = app.appName;
                    if (appName.isEmpty || appName == app.packageName) {
                      final parts = app.packageName.split('.');
                      appName = parts.last.replaceAll('_', ' ');
                      appName = appName[0].toUpperCase() + appName.substring(1);
                    }

                    // Get brand color
                    final brandColor = _getAppBrandColor(
                      appName,
                      app.packageName,
                    );

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // App Icon (already fetched)
                          if (appInfo?.icon != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                appInfo!.icon!,
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: brandColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.android,
                                color: brandColor,
                                size: 24,
                              ),
                            ),
                          const SizedBox(width: 14),
                          // Middle Section - App name + Progress Bar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1F2937),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                // Progress Bar with Brand Color
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progress,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: brandColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Usage Time
                          Text(
                            durationText,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
