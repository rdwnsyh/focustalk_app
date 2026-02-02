import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/services/leaderboard_service.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  /// Master list of default apps to monitor
  /// This list will be automatically synced to the database
  static final List<Map<String, dynamic>> defaultApps = [
    // Social Media Apps
    {
      'package_name': 'com.instagram.android',
      'app_name': 'Instagram',
      'category': 'SOCIAL',
      'is_blocked': 0,
      'is_active': 1,
    },
    {
      'package_name': 'com.facebook.katana',
      'app_name': 'Facebook',
      'category': 'SOCIAL',
      'is_blocked': 0,
      'is_active': 1,
    },
    {
      'package_name': 'com.twitter.android',
      'app_name': 'X (Twitter)',
      'category': 'SOCIAL',
      'is_blocked': 0,
      'is_active': 1,
    },
    {
      'package_name': 'com.zhiliaoapp.musically',
      'app_name': 'TikTok',
      'category': 'SOCIAL',
      'is_blocked': 0,
      'is_active': 1,
    },
    {
      'package_name': 'com.whatsapp',
      'app_name': 'WhatsApp',
      'category': 'SOCIAL',
      'is_blocked': 0,
      'is_active': 1,
    },
    {
      'package_name': 'com.google.android.youtube',
      'app_name': 'YouTube',
      'category': 'SOCIAL',
      'is_blocked': 0,
      'is_active': 1,
    },
    // Game Apps
    {
      'package_name': 'com.mobile.legends',
      'app_name': 'Mobile Legends',
      'category': 'GAME',
      'is_blocked': 0,
      'is_active': 1,
    },
    {
      'package_name': 'com.tencent.ig',
      'app_name': 'PUBG Mobile',
      'category': 'GAME',
      'is_blocked': 0,
      'is_active': 1,
    },
    {
      'package_name': 'com.dts.freefireth',
      'app_name': 'Free Fire',
      'category': 'GAME',
      'is_blocked': 0,
      'is_active': 1,
    },
    {
      'package_name': 'com.roblox.client',
      'app_name': 'Roblox',
      'category': 'GAME',
      'is_blocked': 0,
      'is_active': 1,
    },
  ];

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'focustalk.db');
    // For development: Delete old database when schema changes
    // Uncomment ONLY when you need to reset the database completely:
    // await deleteDatabase(path);
    // print('🗑️ Old database deleted - will recreate with fresh data');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Drop and recreate questions table with new schema
      await db.execute('DROP TABLE IF EXISTS questions');
      await db.execute('''
        CREATE TABLE questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          question TEXT NOT NULL,
          correct_answer TEXT NOT NULL,
          option_a TEXT NOT NULL,
          option_b TEXT NOT NULL,
          option_c TEXT,
          option_d TEXT,
          shown_count INTEGER DEFAULT 0
        )
      ''');
    }

    if (oldVersion < 3) {
      // Add is_active column to app_dictionary for toggle ON/OFF
      await db.execute(
        'ALTER TABLE app_dictionary ADD COLUMN is_active INTEGER DEFAULT 1',
      );
      print('✅ Migration: Added is_active column to app_dictionary');
    }

    if (oldVersion < 4) {
      // Create daily_stats table for tracking history
      await db.execute('''
        CREATE TABLE daily_stats (
          date TEXT PRIMARY KEY,
          solved_count INTEGER DEFAULT 0,
          correct_answers INTEGER DEFAULT 0,
          wrong_answers INTEGER DEFAULT 0
        )
      ''');
      print('✅ Migration: Created daily_stats table');
    }

    if (oldVersion < 5) {
      // Add interventions_count column to daily_stats
      await db.execute(
        'ALTER TABLE daily_stats ADD COLUMN interventions_count INTEGER DEFAULT 0',
      );
      print('✅ Migration: Added interventions_count column to daily_stats');
    }

    if (oldVersion < 6) {
      // Add is_solved column to questions table
      await db.execute(
        'ALTER TABLE questions ADD COLUMN is_solved INTEGER DEFAULT 0',
      );
      print('✅ Migration: Added is_solved column to questions table');
    }
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Create app_dictionary table
    await db.execute('''
      CREATE TABLE app_dictionary (
        package_name TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        is_blocked INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // Create questions table with multiple choice options

    // Create daily_stats table for tracking learning history
    await db.execute('''
      CREATE TABLE daily_stats (
        date TEXT PRIMARY KEY,
        solved_count INTEGER DEFAULT 0,
        correct_answers INTEGER DEFAULT 0,
        wrong_answers INTEGER DEFAULT 0,
        interventions_count INTEGER DEFAULT 0
      )
    ''');
    // NOTE: If you change this schema, uninstall the app first to reset the database!
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT,
        option_d TEXT,
        shown_count INTEGER DEFAULT 0,
        is_solved INTEGER DEFAULT 0
      )
    ''');
  }

  /// Seed database with apps and questions
  Future<void> seedDatabase() async {
    await seedDefaultApps(); // Use the new sync method
    await _seedQuestions();
  }

  /// Sync/Seed default apps into database
  /// This method intelligently inserts missing apps and updates categories
  Future<void> seedDefaultApps() async {
    final db = await database;
    int insertedCount = 0;
    int updatedCount = 0;
    int skippedCount = 0;

    print('🔄 Starting app sync process...');
    print('📋 Total apps in master list: ${defaultApps.length}');

    for (var app in defaultApps) {
      final packageName = app['package_name'];

      // Check if app already exists in database
      final existing = await db.query(
        'app_dictionary',
        where: 'package_name = ?',
        whereArgs: [packageName],
      );

      if (existing.isEmpty) {
        // App does NOT exist - insert it
        await db.insert('app_dictionary', {
          'package_name': app['package_name'],
          'category': app['category'],
          'is_blocked': app['is_blocked'] ?? 0,
          'is_active': app['is_active'] ?? 1,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        print('  ✅ Inserted: ${app['app_name']} (${app['package_name']})');
        insertedCount++;
      } else {
        // App exists - check if category needs to be updated
        final existingCategory = existing.first['category'] as String;
        final newCategory = app['category'] as String;

        if (existingCategory != newCategory) {
          // Update category only (preserve is_blocked and is_active)
          await db.update(
            'app_dictionary',
            {'category': newCategory},
            where: 'package_name = ?',
            whereArgs: [packageName],
          );
          print(
            '  🔄 Updated: ${app['app_name']} ($existingCategory → $newCategory)',
          );
          updatedCount++;
        } else {
          print('  ⏭️  Skipped: ${app['app_name']} (already up-to-date)');
          skippedCount++;
        }
      }
    }

    print('═══════════════════════════════════════════════════════');
    print('✅ App sync completed!');
    print('   📥 Inserted: $insertedCount new apps');
    print('   🔄 Updated: $updatedCount apps');
    print('   ⏭️  Skipped: $skippedCount existing apps');
    print('   📊 Total: ${defaultApps.length} apps in master list');
    print('═══════════════════════════════════════════════════════');
  }

  /// Seed dummy apps for testing (DEPRECATED - use seedDefaultApps instead)
  @Deprecated('Use seedDefaultApps() instead')
  Future<void> _seedApps() async {
    final db = await database;

    // Insert dummy apps (INSERT OR IGNORE to avoid duplicates)
    final appsToInsert = [
      {
        'package_name': 'com.instagram.android',
        'category': 'SOCIAL',
        'is_blocked': 0,
        'is_active': 1,
      },
      {
        'package_name': 'com.facebook.katana',
        'category': 'SOCIAL',
        'is_blocked': 0,
        'is_active': 1,
      },
      {
        'package_name': 'com.whatsapp',
        'category': 'COMMUNICATION',
        'is_blocked': 0,
        'is_active': 1,
      },
      {
        'package_name': 'com.mobile.legends',
        'category': 'GAME',
        'is_blocked': 0,
        'is_active': 1,
      },
      {
        'package_name': 'com.google.android.youtube',
        'category': 'ENTERTAINMENT',
        'is_blocked': 0,
        'is_active': 1,
      },
    ];

    print('📝 Inserting ${appsToInsert.length} apps into database...');
    for (var app in appsToInsert) {
      await db.insert(
        'app_dictionary',
        app,
        conflictAlgorithm:
            ConflictAlgorithm.replace, // Use REPLACE to ensure update
      );
    }

    print('✅ ${appsToInsert.length} apps seeded successfully!');
  }

  /// Seed English quiz questions - only if table is empty
  Future<void> _seedQuestions() async {
    final db = await database;

    // Check if questions already exist
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions'),
    );

    if (count != null && count > 0) {
      print('📚 Questions already exist ($count questions), skipping seed');
      return;
    }

    print('📝 Inserting quiz questions into database...');

    // Insert English quiz questions
    final questionsToInsert = [
      {
        'question': 'What is the synonym of "Start"?',
        'correct_answer': 'Begin',
        'option_a': 'Begin',
        'option_b': 'Stop',
        'option_c': 'End',
        'option_d': 'Finish',
      },
      {
        'question': 'What is the antonym of "Happy"?',
        'correct_answer': 'Sad',
        'option_a': 'Joyful',
        'option_b': 'Sad',
        'option_c': 'Excited',
        'option_d': 'Cheerful',
      },
      {
        'question':
            'Choose the correct grammar: "She ___ to school every day."',
        'correct_answer': 'goes',
        'option_a': 'go',
        'option_b': 'goes',
        'option_c': 'going',
        'option_d': 'gone',
      },
      {
        'question': 'What is the plural of "Child"?',
        'correct_answer': 'Children',
        'option_a': 'Childs',
        'option_b': 'Children',
        'option_c': 'Childrens',
        'option_d': 'Child',
      },
      {
        'question': 'Which word means "to delay or postpone"?',
        'correct_answer': 'Procrastinate',
        'option_a': 'Rush',
        'option_b': 'Hurry',
        'option_c': 'Procrastinate',
        'option_d': 'Accelerate',
      },
      {
        'question': 'What is the past tense of "Run"?',
        'correct_answer': 'Ran',
        'option_a': 'Runned',
        'option_b': 'Run',
        'option_c': 'Ran',
        'option_d': 'Running',
      },
      {
        'question': 'Choose the correct sentence:',
        'correct_answer': 'I have been studying.',
        'option_a': 'I has been studying.',
        'option_b': 'I have been studying.',
        'option_c': 'I have be studying.',
        'option_d': 'I has be studying.',
      },
      {
        'question': 'What does "Diligent" mean?',
        'correct_answer': 'Hardworking',
        'option_a': 'Lazy',
        'option_b': 'Hardworking',
        'option_c': 'Careless',
        'option_d': 'Slow',
      },
      {
        'question': 'Which is a noun?',
        'correct_answer': 'Book',
        'option_a': 'Quickly',
        'option_b': 'Beautiful',
        'option_c': 'Book',
        'option_d': 'Run',
      },
      {
        'question': 'What is the opposite of "Ancient"?',
        'correct_answer': 'Modern',
        'option_a': 'Old',
        'option_b': 'Historic',
        'option_c': 'Modern',
        'option_d': 'Traditional',
      },
    ];

    for (var question in questionsToInsert) {
      await db.insert(
        'questions',
        question,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    print('📚 ${questionsToInsert.length} questions seeded successfully!');
  }

  /// Get a random question using Least Recently Used logic
  /// Questions with lower shown_count are prioritized
  /// Get a random unsolved question (prioritize unsolved, fall back to any)
  Future<Map<String, dynamic>?> getRandomQuestion() async {
    final db = await database;

    // First, try to fetch an unsolved question
    var results = await db.query(
      'questions',
      where: 'is_solved = 0',
      orderBy: 'RANDOM()',
      limit: 1,
    );

    // If no unsolved questions, reset all and fetch any random
    if (results.isEmpty) {
      print('⚠️ All questions solved! Resetting is_solved flag...');
      await db.rawUpdate('UPDATE questions SET is_solved = 0');

      results = await db.query('questions', orderBy: 'RANDOM()', limit: 1);
    }

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Get a random question EXCLUDING a specific question ID (No Duplicate Logic)
  /// This ensures the same question doesn't appear twice in a row
  Future<Map<String, dynamic>?> getRandomQuestionExcluding(
    int excludeId,
  ) async {
    final db = await database;

    // First, try to fetch an unsolved question (excluding the current one)
    var results = await db.query(
      'questions',
      where: 'is_solved = 0 AND id != ?',
      whereArgs: [excludeId],
      orderBy: 'RANDOM()',
      limit: 1,
    );

    // If no unsolved questions (excluding current), reset all and try again
    if (results.isEmpty) {
      print('⚠️ No other unsolved questions! Checking all questions...');

      // Try to get any question except the excluded one
      results = await db.query(
        'questions',
        where: 'id != ?',
        whereArgs: [excludeId],
        orderBy: 'RANDOM()',
        limit: 1,
      );

      // If still empty, it means there's only 1 question in the database
      if (results.isEmpty) {
        print('⚠️ Only 1 question in database! Resetting and returning same.');
        await db.rawUpdate('UPDATE questions SET is_solved = 0');
        // Return the only question available
        results = await db.query('questions', orderBy: 'RANDOM()', limit: 1);
      }
    }

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Get unsolved questions count
  Future<int> getUnsolvedQuestionsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions WHERE is_solved = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mark question as solved
  /// This sets is_solved = 1 so it won't be fetched until reset
  Future<void> markQuestionAsSolved(int questionId) async {
    final db = await database;
    await db.rawUpdate('UPDATE questions SET is_solved = 1 WHERE id = ?', [
      questionId,
    ]);
    print('✅ Question $questionId marked as solved');
  }

  /// Reset all questions (set is_solved = 0)
  Future<void> resetAllQuestions() async {
    final db = await database;
    await db.rawUpdate('UPDATE questions SET is_solved = 0');
    print('🔄 All questions reset');
  }

  /// Get category by package name
  Future<String?> getCategory(String packageName) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'app_dictionary',
      columns: ['category'],
      where: 'package_name = ?',
      whereArgs: [packageName],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['category'] as String;
    }
    return null; // App not found in dictionary
  }

  /// Toggle app blocking status (ON/OFF)
  /// @param packageName: The app package name
  /// @param isActive: true = blocking enabled, false = blocking disabled
  Future<void> toggleAppStatus(String packageName, bool isActive) async {
    final db = await database;
    await db.update(
      'app_dictionary',
      {'is_active': isActive ? 1 : 0},
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
    print('🔄 Updated $packageName: is_active = ${isActive ? 1 : 0}');
  }

  /// Get all apps from app_dictionary
  /// Returns: List of maps containing package_name, category, is_blocked, is_active
  Future<List<Map<String, dynamic>>> getAllApps() async {
    final db = await database;
    return await db.query('app_dictionary');
  }

  /// Check if app blocking is active
  /// Returns: true if blocking is ON, false if OFF, null if app not found
  Future<bool?> isAppActive(String packageName) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'app_dictionary',
      columns: ['is_active'],
      where: 'package_name = ?',
      whereArgs: [packageName],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['is_active'] == 1;
    }
    return null;
  }

  /// Add or update app in dictionary
  Future<int> insertOrUpdateApp({
    required String packageName,
    required String category,
    int isBlocked = 0,
  }) async {
    final db = await database;
    return await db.insert('app_dictionary', {
      'package_name': packageName,
      'category': category,
      'is_blocked': isBlocked,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update app blocked status
  Future<int> updateAppBlockedStatus(String packageName, bool isBlocked) async {
    final db = await database;
    return await db.update(
      'app_dictionary',
      {'is_blocked': isBlocked ? 1 : 0},
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  /// Delete app from dictionary
  Future<int> deleteApp(String packageName) async {
    final db = await database;
    return await db.delete(
      'app_dictionary',
      where: 'package_name = ?',
      whereArgs: [packageName],
    );
  }

  /// Get all questions
  Future<List<Map<String, dynamic>>> getAllQuestions() async {
    final db = await database;
    return await db.query('questions');
  }

  /// Insert question
  Future<int> insertQuestion({
    required String question,
    required String answer,
  }) async {
    final db = await database;
    return await db.insert('questions', {
      'question': question,
      'answer': answer,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Update question
  Future<int> updateQuestion({
    required int id,
    required String question,
    required String answer,
  }) async {
    final db = await database;
    return await db.update(
      'questions',
      {'question': question, 'answer': answer},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete question
  Future<int> deleteQuestion(int id) async {
    final db = await database;
    return await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  /// Get apps by category
  Future<List<Map<String, dynamic>>> getAppsByCategory(String category) async {
    final db = await database;
    return await db.query(
      'app_dictionary',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  /// Check if app exists in dictionary
  Future<bool> appExists(String packageName) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'app_dictionary',
      where: 'package_name = ?',
      whereArgs: [packageName],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Get question count
  Future<int> getQuestionCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions'),
    );
    return count ?? 0;
  }

  /// Get app count
  Future<int> getAppCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM app_dictionary'),
    );
    return count ?? 0;
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('app_dictionary');
    await db.delete('questions');
    print('✅ All data cleared!');
  }

  /// Reset database (drop and recreate)
  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'focustalk.db');
    await deleteDatabase(path);
    _database = null;
    _database = await _initDatabase();
    print('✅ Database reset!');
  }

  // ==================== DAILY GOAL MANAGEMENT ====================

  /// Get daily goal (default 20)
  Future<int> getDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('daily_goal') ?? 20;
  }

  /// Set daily goal
  Future<void> setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_goal', goal);
    print('📊 Daily goal set to: $goal');
  }

  /// Get questions solved today
  Future<int> getSolvedToday() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset the counter (new day)
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final lastSolvedDate = prefs.getString('last_solved_date') ?? '';

    if (today != lastSolvedDate) {
      // New day - reset counter
      await prefs.setInt('solved_today', 0);
      await prefs.setString('last_solved_date', today);
      print('🌅 New day detected - counter reset to 0');
      return 0;
    }

    return prefs.getInt('solved_today') ?? 0;
  }

  /// Increment solved count and check if goal is met
  Future<bool> incrementSolvedCount() async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure we're on the correct day
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('last_solved_date', today);

    // Increment counter
    final currentCount = await getSolvedToday();
    final newCount = currentCount + 1;
    await prefs.setInt('solved_today', newCount);

    // Check if goal is met
    final goal = await getDailyGoal();
    final goalMet = newCount >= goal;

    print('✅ Question solved! Progress: $newCount/$goal');
    if (goalMet) {
      print('🎉 Daily goal achieved! You are free today!');
    }

    return goalMet; // Return true if goal is met
  }

  /// Check if daily goal is met
  Future<bool> isDailyGoalMet() async {
    final solvedToday = await getSolvedToday();
    final goal = await getDailyGoal();
    return solvedToday >= goal;
  }

  /// Get progress percentage (0-100)
  Future<double> getProgressPercentage() async {
    final solvedToday = await getSolvedToday();
    final goal = await getDailyGoal();
    if (goal == 0) return 0.0;
    return (solvedToday / goal * 100).clamp(0.0, 100.0);
  }

  // ============================================================================
  // STATISTICS TRACKING
  // ============================================================================

  /// Update daily stats (UPSERT) - Called whenever user answers a question
  Future<void> updateStats(bool isCorrect) async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    // Try to get existing record for today
    final existing = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [today],
    );

    if (existing.isEmpty) {
      // INSERT new record
      await db.insert('daily_stats', {
        'date': today,
        'solved_count': 1,
        'correct_answers': isCorrect ? 1 : 0,
        'wrong_answers': isCorrect ? 0 : 1,
        'interventions_count': 0,
      });
      print('📊 Stats: Created new record for $today');
    } else {
      // UPDATE existing record
      final current = existing.first;
      await db.update(
        'daily_stats',
        {
          'solved_count': (current['solved_count'] as int) + 1,
          'correct_answers':
              (current['correct_answers'] as int) + (isCorrect ? 1 : 0),
          'wrong_answers':
              (current['wrong_answers'] as int) + (isCorrect ? 0 : 1),
        },
        where: 'date = ?',
        whereArgs: [today],
      );
      print('📊 Stats: Updated record for $today');
    }

    // ==================== SYNC WITH BACKEND SERVER ====================
    // Fire-and-forget: Sync progress to leaderboard without blocking UI
    try {
      // Determine if we increment server-side total_solved
      final int solvedIncrement = isCorrect ? 1 : 0;

      // Get current streak
      final int currentStreak = await getCurrentStreak();

      // Sync to backend (fire-and-forget, don't await)
      LeaderboardService()
          .syncProgress(solvedIncrement, currentStreak)
          .then((_) {
            print(
              '🔄 Synced to server: +$solvedIncrement solved, streak: $currentStreak',
            );
          })
          .catchError((error) {
            print('⚠️ Failed to sync to server: $error');
            // Internet error won\'t crash the app - local data is still saved
          });
    } catch (e) {
      print('⚠️ Sync error (non-critical): $e');
    }
  }

  /// Increment intervention count (overlay triggered)
  Future<void> incrementIntervention() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    // Try to get existing record for today
    final existing = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [today],
    );

    if (existing.isEmpty) {
      // INSERT new record
      await db.insert('daily_stats', {
        'date': today,
        'solved_count': 0,
        'correct_answers': 0,
        'wrong_answers': 0,
        'interventions_count': 1,
      });
      print('🛡️ Intervention: Created new record for $today');
    } else {
      // UPDATE existing record
      final current = existing.first;
      await db.update(
        'daily_stats',
        {
          'interventions_count':
              (current['interventions_count'] as int? ?? 0) + 1,
        },
        where: 'date = ?',
        whereArgs: [today],
      );
      print(
        '🛡️ Intervention: Blocked distraction #${(current['interventions_count'] as int? ?? 0) + 1}',
      );
    }
  }

  /// Get last 7 days of statistics for charts
  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final db = await database;
    final today = DateTime.now();
    final List<Map<String, dynamic>> weeklyData = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateString = date.toIso8601String().split('T')[0];

      final result = await db.query(
        'daily_stats',
        where: 'date = ?',
        whereArgs: [dateString],
      );

      if (result.isEmpty) {
        // No data for this day
        weeklyData.add({
          'date': dateString,
          'solved_count': 0,
          'correct_answers': 0,
          'wrong_answers': 0,
          'interventions_count': 0,
        });
      } else {
        weeklyData.add(result.first);
      }
    }

    return weeklyData;
  }

  /// Get total all-time stats
  Future<Map<String, int>> getTotalStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(solved_count) as total_solved,
        SUM(correct_answers) as total_correct,
        SUM(wrong_answers) as total_wrong,
        SUM(interventions_count) as total_interventions
      FROM daily_stats
    ''');

    if (result.isEmpty || result.first['total_solved'] == null) {
      return {
        'total_solved': 0,
        'total_correct': 0,
        'total_wrong': 0,
        'total_interventions': 0,
      };
    }

    return {
      'total_solved': result.first['total_solved'] as int? ?? 0,
      'total_correct': result.first['total_correct'] as int? ?? 0,
      'total_wrong': result.first['total_wrong'] as int? ?? 0,
      'total_interventions': result.first['total_interventions'] as int? ?? 0,
    };
  }

  /// Calculate current streak (consecutive days)
  Future<int> getCurrentStreak() async {
    final db = await database;
    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dateString = date.toIso8601String().split('T')[0];

      final result = await db.query(
        'daily_stats',
        where: 'date = ? AND solved_count > 0',
        whereArgs: [dateString],
      );

      if (result.isEmpty) {
        break; // Streak broken
      }
      streak++;
    }

    return streak;
  }
}
