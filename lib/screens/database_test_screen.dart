import 'package:flutter/material.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:focustalk_app/services/background_service.dart';

class DatabaseTestScreen extends StatefulWidget {
  const DatabaseTestScreen({super.key});

  @override
  State<DatabaseTestScreen> createState() => _DatabaseTestScreenState();
}

class _DatabaseTestScreenState extends State<DatabaseTestScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _apps = [];
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apps = await _dbHelper.getAllApps();
      final questions = await _dbHelper.getAllQuestions();

      setState(() {
        _apps = apps;
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _testGetCategory() async {
    final category = await _dbHelper.getCategory('com.instagram.android');
    setState(() {
      _testResult =
          category != null
              ? 'Instagram category: $category'
              : 'Instagram not found';
    });
  }

  Future<void> _testOverlay() async {
    try {
      // Test with full-screen parameters like the background service uses
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        overlayTitle: "FocusTalk Quiz",
        overlayContent: 'Answer the question to continue',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: WindowSize.matchParent,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.center,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Overlay shown!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _startBackgroundService() async {
    try {
      final serviceManager = BackgroundServiceManager();
      await serviceManager.initializeService();
      await serviceManager.startService();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background service started!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Test'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Reload Data',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Test button
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Test Functions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _testGetCategory,
                              icon: const Icon(Icons.search),
                              label: const Text('Test Instagram Category'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _testOverlay,
                              icon: const Icon(Icons.layers),
                              label: const Text('Test Overlay Window'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _startBackgroundService,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Background Service'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 45),
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                              ),
                            ),
                            if (_testResult != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green[300]!),
                                ),
                                child: Text(
                                  _testResult!,
                                  style: TextStyle(
                                    color: Colors.green[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Apps section
                    Text(
                      'Apps in Dictionary (${_apps.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_apps.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No apps found'),
                        ),
                      )
                    else
                      ..._apps.map(
                        (app) => Card(
                          child: ListTile(
                            leading: Icon(
                              _getCategoryIcon(app['category']),
                              color: _getCategoryColor(app['category']),
                            ),
                            title: Text(
                              app['package_name'],
                              style: const TextStyle(fontSize: 12),
                            ),
                            subtitle: Text(app['category']),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    app['is_blocked'] == 1
                                        ? Colors.red[100]
                                        : Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                app['is_blocked'] == 1 ? 'Blocked' : 'Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      app['is_blocked'] == 1
                                          ? Colors.red[900]
                                          : Colors.green[900],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Questions section
                    Text(
                      'Questions (${_questions.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_questions.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No questions found'),
                        ),
                      )
                    else
                      ..._questions.map(
                        (question) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                '${question['id']}',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(question['question']),
                            subtitle: Text(
                              'Answer: ${question['answer']}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'SOCIAL':
        return Icons.people;
      case 'GAME':
        return Icons.sports_esports;
      case 'COMMUNICATION':
        return Icons.chat;
      case 'ENTERTAINMENT':
        return Icons.movie;
      default:
        return Icons.apps;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'SOCIAL':
        return Colors.purple;
      case 'GAME':
        return Colors.red;
      case 'COMMUNICATION':
        return Colors.blue;
      case 'ENTERTAINMENT':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
