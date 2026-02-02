import 'package:flutter/material.dart';
import 'package:focustalk_app/services/leaderboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  late Future<List<dynamic>> _leaderboardFuture;
  String? _currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadLeaderboard();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserEmail = prefs.getString('user_email');
    });
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFEFE5), // Cream
              const Color(0xFFFFF8F0),
              const Color(0xFFFFFBF5),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<dynamic>>(
            future: _leaderboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final leaderboard = snapshot.data!;
              final topThree =
                  leaderboard.where((u) => u['rank'] <= 3).toList();
              final restOfUsers =
                  leaderboard
                      .where((u) => u['rank'] > 3 && u['rank'] <= 20)
                      .toList();

              // Find current user
              final currentUser =
                  _currentUserEmail != null
                      ? leaderboard.firstWhere(
                        (u) => u['email'] == _currentUserEmail,
                        orElse: () => null,
                      )
                      : null;

              return Stack(
                children: [
                  // Main Content with SingleChildScrollView
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        // App Bar
                        _buildAppBar(),

                        // Top 3 Podium
                        if (topThree.isNotEmpty) _buildModernPodium(topThree),

                        // Section Header
                        if (restOfUsers.isNotEmpty) _buildSectionHeader(),

                        // Rest of Rankings
                        if (restOfUsers.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: restOfUsers.length,
                              itemBuilder: (context, index) {
                                final user = restOfUsers[index];
                                final isCurrentUser =
                                    _currentUserEmail != null &&
                                    user['email'] == _currentUserEmail;
                                return _buildModernUserCard(
                                  rank: user['rank'],
                                  name: user['name'] ?? 'Unknown User',
                                  email: user['email'],
                                  picture: user['picture'],
                                  totalSolved: user['total_solved'] ?? 0,
                                  currentStreak: user['current_streak'] ?? 0,
                                  isCurrentUser: isCurrentUser,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Sticky Bottom - Current User Rank
                  if (currentUser != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildStickyCurrentUserRank(currentUser),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildAppBar(),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFFFF6B35),
                  strokeWidth: 3,
                ),
                SizedBox(height: 16),
                Text(
                  'Loading rankings...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              onPressed: () => Navigator.pop(context),
              color: const Color(0xFF1F2937),
            ),
          ),
          const Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Leaderboard',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text('🏆', style: TextStyle(fontSize: 26)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildModernPodium(List<dynamic> topThree) {
    // Organize: [2nd, 1st, 3rd] for podium display
    final Map<int, dynamic> users = {};
    for (var user in topThree) {
      users[user['rank']] = user;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Avatars Row - Increased height to prevent overflow
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 2nd place (left, lower)
                if (users.containsKey(2))
                  Expanded(
                    child: _buildPodiumAvatar(
                      rank: 2,
                      name: users[2]['name'] ?? 'Unknown',
                      picture: users[2]['picture'],
                      points: users[2]['total_solved'] ?? 0,
                      streak: users[2]['current_streak'] ?? 0,
                      color: const Color(0xFFC0C0C0), // Silver
                      height: 185,
                    ),
                  ),

                const SizedBox(width: 10),

                // 1st place (center, highest)
                if (users.containsKey(1))
                  Expanded(
                    child: _buildPodiumAvatar(
                      rank: 1,
                      name: users[1]['name'] ?? 'Unknown',
                      picture: users[1]['picture'],
                      points: users[1]['total_solved'] ?? 0,
                      streak: users[1]['current_streak'] ?? 0,
                      color: const Color(0xFFFFD700), // Gold
                      height: 220,
                    ),
                  ),

                const SizedBox(width: 10),

                // 3rd place (right, lower)
                if (users.containsKey(3))
                  Expanded(
                    child: _buildPodiumAvatar(
                      rank: 3,
                      name: users[3]['name'] ?? 'Unknown',
                      picture: users[3]['picture'],
                      points: users[3]['total_solved'] ?? 0,
                      streak: users[3]['current_streak'] ?? 0,
                      color: const Color(0xFFCD7F32), // Bronze
                      height: 165,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Podium Base
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place base
              if (users.containsKey(2))
                Expanded(
                  child: _buildPodiumBase(2, const Color(0xFFC0C0C0), 80),
                ),
              const SizedBox(width: 10),
              // 1st place base
              if (users.containsKey(1))
                Expanded(
                  child: _buildPodiumBase(1, const Color(0xFFFFD700), 120),
                ),
              const SizedBox(width: 10),
              // 3rd place base
              if (users.containsKey(3))
                Expanded(
                  child: _buildPodiumBase(3, const Color(0xFFCD7F32), 60),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumAvatar({
    required int rank,
    required String name,
    String? picture,
    required int points,
    required int streak,
    required Color color,
    required double height,
  }) {
    final avatarSize = rank == 1 ? 60.0 : 50.0;
    final String medal =
        rank == 1
            ? '👑'
            : rank == 2
            ? '🥈'
            : '🥉';

    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Medal/Crown with spacing
          if (rank == 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(medal, style: const TextStyle(fontSize: 28)),
            ),

          // Avatar with border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  picture != null && picture.isNotEmpty
                      ? NetworkImage(picture)
                      : null,
              child:
                  picture == null || picture.isEmpty
                      ? Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: avatarSize / 2.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                      : null,
            ),
          ),

          const SizedBox(height: 8),

          // Name - wrapped with Flexible to prevent overflow
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: rank == 1 ? 13 : 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Points
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: rank == 1 ? 14 : 11,
              vertical: rank == 1 ? 7 : 6,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 11),
                const SizedBox(width: 4),
                Text(
                  '$points',
                  style: TextStyle(
                    fontSize: rank == 1 ? 11 : 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Streak
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 3),
              Text(
                '$streak',
                style: TextStyle(
                  fontSize: rank == 1 ? 10 : 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'day${streak != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: rank == 1 ? 8 : 7,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626).withOpacity(0.8),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildPodiumBase(int rank, Color color, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.5),
            color.withOpacity(0.25),
            color.withOpacity(0.08),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: rank == 1 ? 56 : 48,
            fontWeight: FontWeight.w900,
            color: color.withOpacity(0.5),
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 28, 20, 18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.08),
            const Color(0xFFFFAA64).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Top Rankings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernUserCard({
    required int rank,
    required String name,
    String? email,
    String? picture,
    required int totalSolved,
    required int currentStreak,
    bool isCurrentUser = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient:
            isCurrentUser
                ? const LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : null,
        color: isCurrentUser ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            isCurrentUser
                ? Border.all(color: const Color(0xFF60A5FA), width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color:
                isCurrentUser
                    ? const Color(0xFF1E40AF).withOpacity(0.35)
                    : Colors.black.withOpacity(0.06),
            blurRadius: isCurrentUser ? 18 : 12,
            spreadRadius: isCurrentUser ? 1 : 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient:
                    rank <= 10
                        ? const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
                color: rank <= 10 ? null : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                boxShadow:
                    rank <= 10
                        ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B35).withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                        : null,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: rank <= 10 ? Colors.white : const Color(0xFF6B7280),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isCurrentUser
                          ? const Color(0xFF60A5FA)
                          : rank <= 10
                          ? const Color(0xFFFF6B35).withOpacity(0.3)
                          : const Color(0xFFE5E7EB),
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 26,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 12),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isCurrentUser
                              ? Colors.white
                              : const Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Points Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              isCurrentUser
                                  ? LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.2),
                                    ],
                                  )
                                  : LinearGradient(
                                    colors: [
                                      const Color(0xFFFF6B35).withOpacity(0.15),
                                      const Color(0xFFFF8C42).withOpacity(0.1),
                                    ],
                                  ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isCurrentUser
                                    ? Colors.white.withOpacity(0.3)
                                    : const Color(0xFFFF6B35).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color:
                                  isCurrentUser
                                      ? Colors.white
                                      : const Color(0xFFFF6B35),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalSolved',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    isCurrentUser
                                        ? Colors.white
                                        : const Color(0xFFFF6B35),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'solved',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    isCurrentUser
                                        ? Colors.white.withOpacity(0.8)
                                        : const Color(
                                          0xFFFF6B35,
                                        ).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Streak Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              isCurrentUser
                                  ? LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.2),
                                    ],
                                  )
                                  : LinearGradient(
                                    colors: [
                                      Colors.red.shade50,
                                      Colors.red.shade100.withOpacity(0.3),
                                    ],
                                  ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isCurrentUser
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '$currentStreak',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    isCurrentUser
                                        ? Colors.white
                                        : const Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'day${currentStreak != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color:
                                    isCurrentUser
                                        ? Colors.white.withOpacity(0.8)
                                        : const Color(
                                          0xFFDC2626,
                                        ).withOpacity(0.7),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStickyCurrentUserRank(dynamic user) {
    return Container(
      margin: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.45),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // "You" Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'YOU',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withOpacity(0.3),
                backgroundImage:
                    user['picture'] != null && user['picture'].isNotEmpty
                        ? NetworkImage(user['picture'])
                        : null,
                child:
                    user['picture'] == null || user['picture'].isEmpty
                        ? Text(
                          user['name'][0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'] ?? 'You',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user['total_solved']}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'solved',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(
                              '${user['current_streak']}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'day${user['current_streak'] != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
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

            // Rank
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '#${user['rank']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade50,
                          Colors.red.shade100.withOpacity(0.5),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 56,
                      color: Colors.red.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please check your connection and try again',
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _refreshLeaderboard,
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    label: const Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade50,
                        Colors.orange.shade100.withOpacity(0.5),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.leaderboard_outlined,
                    size: 56,
                    color: Colors.orange.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Rankings Yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Be the first to complete a quiz\nand join the leaderboard!',
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
