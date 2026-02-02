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
  String _selectedCategory = 'All'; // Filter state: 'All', 'Social', 'Game'

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  /// Get filtered apps based on selected category
  List<Map<String, dynamic>> get _filteredApps {
    if (_selectedCategory == 'All') {
      return _monitoredApps;
    } else if (_selectedCategory == 'Social') {
      // Social category only
      return _monitoredApps.where((app) {
        final category = (app['category'] as String).toUpperCase();
        return category == 'SOCIAL';
      }).toList();
    } else if (_selectedCategory == 'Game') {
      // Game category
      return _monitoredApps.where((app) {
        final category = (app['category'] as String).toUpperCase();
        return category == 'GAME';
      }).toList();
    }
    return _monitoredApps;
  }

  /// Change category filter
  void _changeFilter(String category) {
    setState(() {
      _selectedCategory = category;
    });
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

  /// Convert package name to readable app name
  String _getReadableAppName(String packageName) {
    // Map of common package names to readable names
    final Map<String, String> appNameMap = {
      'com.instagram.android': 'Instagram',
      'com.facebook.katana': 'Facebook',
      'com.twitter.android': 'X (Twitter)',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.whatsapp': 'WhatsApp',
      'com.google.android.youtube': 'YouTube',
      'com.mobile.legends': 'Mobile Legends',
      'com.tencent.ig': 'PUBG Mobile',
      'com.dts.freefireth': 'Free Fire',
      'com.roblox.client': 'Roblox',
    };

    // Return mapped name if exists
    if (appNameMap.containsKey(packageName)) {
      return appNameMap[packageName]!;
    }

    // Fallback: Capitalize the last part of package name
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      final lastPart = parts.last;
      return lastPart[0].toUpperCase() + lastPart.substring(1);
    }

    return packageName;
  }

  /// Get app avatar color based on package name (brand colors) or category
  Color _getAppAvatarColor(String packageName, String category) {
    // Brand-specific colors
    switch (packageName) {
      case 'com.whatsapp':
        return const Color(0xFF25D366); // WhatsApp Green
      case 'com.google.android.youtube':
        return const Color(0xFFFF0000); // YouTube Red
      case 'com.instagram.android':
        return const Color(0xFFE4405F); // Instagram Pink/Red
      case 'com.facebook.katana':
        return const Color(0xFF1877F2); // Facebook Blue
      case 'com.twitter.android':
        return const Color(0xFF1DA1F2); // Twitter/X Blue
      case 'com.zhiliaoapp.musically':
        return const Color(0xFF000000); // TikTok Black
    }

    // Category fallback colors
    switch (category.toUpperCase()) {
      case 'SOCIAL':
        return const Color(0xFFE91E63); // Pink
      case 'COMMUNICATION':
        return const Color(0xFF00BCD4); // Cyan
      case 'ENTERTAINMENT':
        return const Color(0xFF9C27B0); // Purple
      case 'GAME':
        return const Color(0xFFFF5722); // Deep Orange
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  /// Get first letter of app name for avatar
  String _getAppInitial(String appName) {
    return appName.isNotEmpty ? appName[0].toUpperCase() : '?';
  }

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'SOCIAL':
        return Icons.people_rounded;
      case 'COMMUNICATION':
        return Icons.chat_bubble_rounded;
      case 'ENTERTAINMENT':
        return Icons.movie_rounded;
      case 'GAME':
        return Icons.sports_esports_rounded;
      case 'SHOPPING':
        return Icons.shopping_cart_rounded;
      case 'NEWS':
        return Icons.article_rounded;
      default:
        return Icons.phone_android;
    }
  }

  /// Get category badge color (pastel)
  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'SOCIAL':
        return const Color(0xFF2196F3); // Blue
      case 'COMMUNICATION':
        return const Color(0xFF00BCD4); // Cyan
      case 'ENTERTAINMENT':
        return const Color(0xFF9C27B0); // Purple
      case 'GAME':
        return const Color(0xFFFF5722); // Deep Orange
      case 'SHOPPING':
        return const Color(0xFF4CAF50); // Green
      case 'NEWS':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Monitored Apps',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFF6B35), // Primary Orange
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
              : Column(
                children: [
                  // Filter Chip Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('All', Icons.apps_rounded),
                          const SizedBox(width: 8),
                          _buildFilterChip('Social', Icons.people_rounded),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            'Game',
                            Icons.sports_esports_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Apps List
                  Expanded(
                    child:
                        _filteredApps.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.filter_list_off_rounded,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No $_selectedCategory apps found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try selecting a different filter',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredApps.length,
                              separatorBuilder:
                                  (context, index) =>
                                      const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final app = _filteredApps[index];
                                return _buildAppCard(app);
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  /// Build modern filter chip widget with stadium border
  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    const primaryOrange = Color(0xFFFF6B35);

    return GestureDetector(
      onTap: () => _changeFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryOrange : Colors.white,
          border:
              isSelected
                  ? null
                  : Border.all(color: Colors.grey[300]!, width: 1.5),
          borderRadius: BorderRadius.circular(25), // Stadium border
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build modern app card with premium design
  Widget _buildAppCard(Map<String, dynamic> app) {
    const primaryOrange = Color(0xFFFF6B35);
    final packageName = app['package_name'] as String;
    final category = app['category'] as String;
    final isActive = (app['is_active'] as int? ?? 1) == 1;
    final appName = _getReadableAppName(packageName);
    final avatarColor = _getAppAvatarColor(packageName, category);
    final initial = _getAppInitial(appName);
    final categoryColor = _getCategoryColor(category);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // App Icon (Colored Circle with Initial)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // App Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Readable App Name
                  Text(
                    appName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 14,
                          color: categoryColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          category,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Toggle Switch
            Switch.adaptive(
              value: isActive,
              onChanged: (value) {
                _toggleAppStatus(packageName, isActive);
              },
              activeColor: primaryOrange,
              activeTrackColor: primaryOrange.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
