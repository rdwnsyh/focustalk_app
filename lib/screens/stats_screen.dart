import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:focustalk_app/widgets/usage_list.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = true;

  // Stats data
  int _currentStreak = 0;
  List<Map<String, dynamic>> _weeklyData = [];
  Map<String, int> _totalStats = {};

  // Color Palette (Modernized)
  final Color _bgColor = const Color.fromARGB(255, 253, 245, 230);
  final Color _primaryPurple = const Color(0xFFFF8C42);
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final streak = await _dbHelper.getCurrentStreak();
      final weekly = await _dbHelper.getWeeklyStats();
      final total = await _dbHelper.getTotalStats();

      if (mounted) {
        setState(() {
          _currentStreak = streak;
          _weeklyData = weekly;
          _totalStats = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      extendBodyBehindAppBar: true, // Agar konten bisa scroll di bawah app bar
      appBar: AppBar(
        title: const Text(
          'Your Statistics',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: _primaryPurple, // Fallback color
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryPurple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryPurple))
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: _primaryPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20), // Top padding for extendBodyBehindAppBar
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Streak Card
                    _buildStreakCard(),
                    const SizedBox(height: 24),

                    // Weekly Progress Bar Chart
                    _buildSectionHeader('Weekly Activity', Icons.bar_chart_rounded, Colors.blue),
                    const SizedBox(height: 12),
                    _buildWeeklyProgressSection(),
                    const SizedBox(height: 24),

                    // Focus Impact Section
                    _buildSectionHeader('Focus Impact', Icons.psychology_rounded, Colors.purple),
                    const SizedBox(height: 12),
                    _buildFocusImpactSection(),
                    const SizedBox(height: 24),

                    // Top Distractions Today
                    _buildSectionHeader('Top Distractions', Icons.phone_android_rounded, Colors.red),
                    const SizedBox(height: 12),
                    _buildTopDistractionsSection(),
                    const SizedBox(height: 24),

                    // Accuracy Pie Chart
                    _buildSectionHeader('Accuracy Rate', Icons.pie_chart_rounded, Colors.green),
                    const SizedBox(height: 12),
                    _buildAccuracySection(),
                    const SizedBox(height: 24),

                    // Total Summary Cards
                    _buildSectionHeader('All-Time Summary', Icons.history_rounded, Colors.orange),
                    const SizedBox(height: 12),
                    _buildTotalSummary(),
                    const SizedBox(height: 40), // Bottom spacer
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Streak Card (Modern Gradient)
  Widget _buildStreakCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 8),
              Text(
                '$_currentStreak',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'DAY STREAK',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentStreak == 0 ? 'Start today!' : 'Keep the fire burning!',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Weekly Progress Bar Chart (Clean Design)
  Widget _buildWeeklyProgressSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 220,
        child: _weeklyData.isEmpty
            ? const Center(child: Text('No data available', style: TextStyle(color: Colors.grey)))
            : BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxYValue(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey.shade800,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.round()}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(
                              text: '\nquestions',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _getDayLabel(value.toInt()),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade100,
                        strokeWidth: 1,
                        dashArray: [5, 5], // Dashed lines
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(),
                ),
              ),
      ),
    );
  }

  /// Accuracy Pie Chart (Modern Donut)
  Widget _buildAccuracySection() {
    final totalCorrect = _totalStats['total_correct'] ?? 0;
    final totalWrong = _totalStats['total_wrong'] ?? 0;
    final total = totalCorrect + totalWrong;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: total == 0
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'Start solving to see accuracy!',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40, // Donut style
                        sections: [
                          PieChartSectionData(
                            value: totalCorrect.toDouble(),
                            title: '${(totalCorrect / total * 100).toStringAsFixed(0)}%',
                            color: const Color(0xFF10B981), // Modern Emerald Green
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: totalWrong.toDouble(),
                            title: '', // Hide label for wrong if small
                            color: const Color(0xFFEF4444), // Modern Red
                            radius: 40, // Slightly smaller
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Correct', const Color(0xFF10B981), totalCorrect),
                      const SizedBox(height: 16),
                      _buildLegendItem('Wrong', const Color(0xFFEF4444), totalWrong),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Total Summary Cards
  Widget _buildTotalSummary() {
    final totalSolved = _totalStats['total_solved'] ?? 0;
    final totalCorrect = _totalStats['total_correct'] ?? 0;
    final accuracy = totalSolved > 0
        ? (totalCorrect / totalSolved * 100).toStringAsFixed(1)
        : '0.0';

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Questions\nSolved',
            totalSolved.toString(),
            Icons.quiz_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Overall\nAccuracy',
            '$accuracy%',
            Icons.verified_rounded,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Focus Impact Section
  Widget _buildFocusImpactSection() {
    final totalInterventions = _totalStats['total_interventions'] ?? 0;
    final timeSavedMinutes = totalInterventions * 5;
    final hours = timeSavedMinutes ~/ 60;
    final minutes = timeSavedMinutes % 60;

    String timeSavedText;
    if (hours > 0 && minutes > 0) {
      timeSavedText = '${hours}h ${minutes}m';
    } else if (hours > 0) {
      timeSavedText = '${hours} Hours';
    } else {
      timeSavedText = '$minutes Mins';
    }

    return Row(
      children: [
        Expanded(
          child: _buildFocusCard(
            icon: Icons.shield_rounded,
            value: totalInterventions.toString(),
            label: 'Distractions\nBlocked',
            color: const Color(0xFF6366F1), // Indigo
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildFocusCard(
            icon: Icons.hourglass_bottom_rounded,
            value: timeSavedText,
            label: 'Estimated\nTime Saved',
            color: const Color(0xFF8B5CF6), // Violet
          ),
        ),
      ],
    );
  }

  Widget _buildFocusCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

/// Top Distractions Today Section
  Widget _buildTopDistractionsSection() {
    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
      
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 16, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const UsageList(),
    );
  }

  /// Helper: Build bar groups for chart
  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(_weeklyData.length, (index) {
      final solvedCount = _weeklyData[index]['solved_count'] as int;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: solvedCount.toDouble(),
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade600],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 16,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxYValue(), // Full height background
              color: Colors.grey.shade50,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      );
    });
  }

  /// Helper: Get day label (Mon, Tue, etc.)
  String _getDayLabel(int index) {
    if (index < 0 || index >= _weeklyData.length) return '';
    final dateString = _weeklyData[index]['date'] as String;
    final date = DateTime.parse(dateString);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Helper: Get max Y value for chart scaling
  double _getMaxYValue() {
    if (_weeklyData.isEmpty) return 10;
    final maxSolved = _weeklyData
        .map((e) => e['solved_count'] as int)
        .reduce((a, b) => a > b ? a : b);
    return (maxSolved + 5).toDouble();
  }
}