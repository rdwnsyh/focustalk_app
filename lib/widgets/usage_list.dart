import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class UsageList extends StatefulWidget {
  const UsageList({super.key});

  @override
  State<UsageList> createState() => _UsageListState();
}

class _UsageListState extends State<UsageList> {
  List<AppUsageInfo> _topApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsageStats();
  }

  Future<void> _fetchUsageStats() async {
    setState(() {
      _isLoading = true;
    });

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

      setState(() {
        _topApps = top5;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching app usage: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_topApps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(Icons.hourglass_empty, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No app usage data today',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _topApps.length,
      itemBuilder: (context, index) {
        final app = _topApps[index];
        return _buildUsageItem(app, index);
      },
    );
  }

  Widget _buildUsageItem(AppUsageInfo app, int index) {
    final duration = app.usage;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    String durationText;
    if (hours > 0) {
      durationText = '${hours}h ${minutes}m';
    } else {
      durationText = '${minutes}m';
    }

    // Calculate percentage for progress bar (relative to top app)
    final maxDuration = _topApps.first.usage.inMinutes;
    final percentage = duration.inMinutes / maxDuration;

    // Get app name (clean package name)
    String appName = app.appName;
    if (appName.isEmpty || appName == app.packageName) {
      // Extract readable name from package name
      final parts = app.packageName.split('.');
      appName = parts.last.replaceAll('_', ' ');
      appName = appName[0].toUpperCase() + appName.substring(1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(index),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // App icon (placeholder)
          FutureBuilder<AppInfo?>(
            future: _getAppIcon(app.packageName),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return Image.memory(
                  snapshot.data!.icon!,
                  width: 40,
                  height: 40,
                );
              }
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.apps, color: Colors.grey[600], size: 24),
              );
            },
          ),
          const SizedBox(width: 12),

          // App info and usage bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        appName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      durationText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getRankColor(index),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<AppInfo?> _getAppIcon(String packageName) async {
    try {
      final app = await InstalledApps.getAppInfo(packageName, null);
      return app;
    } catch (e) {
      return null;
    }
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey[400]!; // Silver
      case 2:
        return Colors.brown[400]!; // Bronze
      default:
        return Colors.blue;
    }
  }
}
