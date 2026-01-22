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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Streak Card
                      _buildStreakCard(),
                      const SizedBox(height: 20),

                      // Weekly Progress Bar Chart
                      _buildWeeklyProgressSection(),
                      const SizedBox(height: 20),

                      // Focus Impact Section
                      _buildFocusImpactSection(),
                      const SizedBox(height: 20),

                      // Top Distractions Today
                      _buildTopDistractionsSection(),
                      const SizedBox(height: 20),

                      // Accuracy Pie Chart
                      _buildAccuracySection(),
                      const SizedBox(height: 20),

                      // Total Summary Cards
                      _buildTotalSummary(),
                    ],
                  ),
                ),
              ),
    );
  }

  /// Streak Card
  Widget _buildStreakCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              '$_currentStreak',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Day Streak',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentStreak == 0
                  ? 'Start your streak today!'
                  : 'Keep up the momentum!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Weekly Progress Bar Chart
  Widget _buildWeeklyProgressSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Weekly Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child:
                  _weeklyData.isEmpty
                      ? const Center(child: Text('No data available'))
                      : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _getMaxYValue(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.blueGrey,
                              getTooltipItem: (
                                group,
                                groupIndex,
                                rod,
                                rodIndex,
                              ) {
                                return BarTooltipItem(
                                  '${rod.toY.round()} questions',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                  return Text(
                                    _getDayLabel(value.toInt()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 12),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.shade300,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: _buildBarGroups(),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  /// Accuracy Pie Chart
  Widget _buildAccuracySection() {
    final totalCorrect = _totalStats['total_correct'] ?? 0;
    final totalWrong = _totalStats['total_wrong'] ?? 0;
    final total = totalCorrect + totalWrong;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Accuracy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            total == 0
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'No data yet. Start solving questions!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
                : Row(
                  children: [
                    // Pie Chart
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                value: totalCorrect.toDouble(),
                                title:
                                    '${(totalCorrect / total * 100).toStringAsFixed(1)}%',
                                color: Colors.green,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              PieChartSectionData(
                                value: totalWrong.toDouble(),
                                title:
                                    '${(totalWrong / total * 100).toStringAsFixed(1)}%',
                                color: Colors.red,
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Legend
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem(
                            'Correct',
                            Colors.green,
                            totalCorrect,
                          ),
                          const SizedBox(height: 12),
                          _buildLegendItem('Wrong', Colors.red, totalWrong),
                        ],
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  /// Total Summary Cards
  Widget _buildTotalSummary() {
    final totalSolved = _totalStats['total_solved'] ?? 0;
    final totalCorrect = _totalStats['total_correct'] ?? 0;
    final totalWrong = _totalStats['total_wrong'] ?? 0;
    final accuracy =
        totalSolved > 0
            ? (totalCorrect / totalSolved * 100).toStringAsFixed(1)
            : '0.0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All-Time Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Solved',
                totalSolved.toString(),
                Icons.quiz,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Accuracy',
                '$accuracy%',
                Icons.verified,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper: Build legend item
  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper: Build summary card
  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
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
      timeSavedText = '$hours Hours $minutes Mins';
    } else if (hours > 0) {
      timeSavedText = '$hours Hours';
    } else {
      timeSavedText = '$minutes Mins';
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple.shade700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Focus Impact',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildFocusCard(
                    icon: Icons.shield,
                    value: totalInterventions.toString(),
                    label: 'Distractions\nBlocked',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFocusCard(
                    icon: Icons.hourglass_bottom,
                    value: timeSavedText,
                    label: 'Time Saved',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Build focus impact card
  Widget _buildFocusCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Top Distractions Today Section
  Widget _buildTopDistractionsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Top Distractions Today',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const UsageList(),
          ],
        ),
      ),
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
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
