import 'package:flutter/material.dart';
import 'package:focustalk_app/services/database_helper.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _monitoredApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  /// Load all monitored apps from database
  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apps = await _dbHelper.getAllApps();
      if (mounted) {
        setState(() {
          _monitoredApps = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading apps: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Toggle app ON/OFF status
  Future<void> _toggleAppStatus(String packageName, bool currentStatus) async {
    try {
      final newStatus = currentStatus ? 0 : 1;
      await _dbHelper.toggleAppStatus(packageName, newStatus == 1);
      _loadApps(); // Refresh list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 1
                  ? 'App monitoring enabled'
                  : 'App monitoring disabled',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error toggling app status: $e');
    }
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social media':
        return Icons.people;
      case 'entertainment':
        return Icons.movie;
      case 'games':
        return Icons.sports_esports;
      case 'shopping':
        return Icons.shopping_cart;
      case 'news':
        return Icons.article;
      default:
        return Icons.phone_android;
    }
  }

  /// Get category color
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'social media':
        return Colors.blue;
      case 'entertainment':
        return Colors.purple;
      case 'games':
        return Colors.orange;
      case 'shopping':
        return Colors.green;
      case 'news':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Monitored Apps',
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
            onPressed: _loadApps,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _monitoredApps.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No apps found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Apps will appear here once detected',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _monitoredApps.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final app = _monitoredApps[index];
                  final packageName = app['package_name'] as String;
                  final category = app['category'] as String;
                  final isActive = (app['is_active'] as int? ?? 1) == 1;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
              ),
    );
  }
}
