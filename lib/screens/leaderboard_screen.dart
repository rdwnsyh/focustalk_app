import 'package:flutter/material.dart';
import 'package:focustalk_app/services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  late Future<List<dynamic>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    setState(() {
      _leaderboardFuture = _leaderboardService.fetchLeaderboard();
    });
  }

  Future<void> _refreshLeaderboard() async {
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Leaderboard 🏆',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshLeaderboard,
        color: Colors.orange,
        child: FutureBuilder<List<dynamic>>(
          future: _leaderboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load leaderboard',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _refreshLeaderboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.leaderboard_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No users yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to complete a quiz!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            final leaderboard = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                final user = leaderboard[index];
                final rank = user['rank'];
                final name = user['name'] ?? 'Unknown User';
                final picture = user['picture'];
                final totalSolved = user['total_solved'] ?? 0;
                final currentStreak = user['current_streak'] ?? 0;

                // Top 3 users get special treatment
                if (rank <= 3) {
                  return _buildTopThreeCard(
                    rank: rank,
                    name: name,
                    picture: picture,
                    totalSolved: totalSolved,
                    currentStreak: currentStreak,
                  );
                }

                // Regular users
                return _buildRegularUserTile(
                  rank: rank,
                  name: name,
                  picture: picture,
                  totalSolved: totalSolved,
                  currentStreak: currentStreak,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopThreeCard({
    required int rank,
    required String name,
    String? picture,
    required int totalSolved,
    required int currentStreak,
  }) {
    // Medal colors
    final Color medalColor =
        rank == 1
            ? const Color(0xFFFFD700) // Gold
            : rank == 2
            ? const Color(0xFFC0C0C0) // Silver
            : const Color(0xFFCD7F32); // Bronze

    final String medal =
        rank == 1
            ? '🥇'
            : rank == 2
            ? '🥈'
            : '🥉';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [medalColor.withOpacity(0.15), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: medalColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Medal + Rank
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: medalColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(medal, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 16),

            // User Avatar
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  picture != null && picture.isNotEmpty
                      ? NetworkImage(picture)
                      : null,
              child:
                  picture == null || picture.isEmpty
                      ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalSolved solved',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentStreak days',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularUserTile({
    required int rank,
    required String name,
    String? picture,
    required int totalSolved,
    required int currentStreak,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank Number
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // User Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  picture != null && picture.isNotEmpty
                      ? NetworkImage(picture)
                      : null,
              child:
                  picture == null || picture.isEmpty
                      ? Text(
                        name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                      : null,
            ),
          ],
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text('$totalSolved solved'),
            const SizedBox(width: 12),
            const Icon(
              Icons.local_fire_department,
              size: 14,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
            Text('$currentStreak'),
          ],
        ),
      ),
    );
  }
}
