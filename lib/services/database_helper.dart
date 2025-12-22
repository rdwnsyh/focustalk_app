import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

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
    // Comment this out in production
    // await deleteDatabase(path);
    return await openDatabase(
      path,
      version: 2,
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
  }

  /// Create tables
  Future<void> _onCreate(Database db, int version) async {
    // Create app_dictionary table
    await db.execute('''
      CREATE TABLE app_dictionary (
        package_name TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        is_blocked INTEGER DEFAULT 0
      )
    ''');

    // Create questions table with multiple choice options
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
        shown_count INTEGER DEFAULT 0
      )
    ''');
  }

  /// Seed database with apps and questions
  Future<void> seedDatabase() async {
    await _seedApps();
    await _seedQuestions();
  }

  /// Seed dummy apps for testing
  Future<void> _seedApps() async {
    final db = await database;

    // Insert dummy apps (INSERT OR IGNORE to avoid duplicates)
    final appsToInsert = [
      {
        'package_name': 'com.instagram.android',
        'category': 'SOCIAL',
        'is_blocked': 0,
      },
      {
        'package_name': 'com.facebook.katana',
        'category': 'SOCIAL',
        'is_blocked': 0,
      },
      {
        'package_name': 'com.whatsapp',
        'category': 'COMMUNICATION',
        'is_blocked': 0,
      },
      {
        'package_name': 'com.mobile.legends',
        'category': 'GAME',
        'is_blocked': 0,
      },
      {
        'package_name': 'com.google.android.youtube',
        'category': 'ENTERTAINMENT',
        'is_blocked': 0,
      },
    ];

    for (var app in appsToInsert) {
      await db.insert(
        'app_dictionary',
        app,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    print('✅ Apps seeded successfully!');
  }

  /// Seed English quiz questions - only if table is empty
  Future<void> _seedQuestions() async {
    final db = await database;

    // Check if questions already exist
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions'),
    );

    if (count != null && count > 0) {
      print('📚 Questions already exist, skipping seed');
      return;
    }

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
  Future<Map<String, dynamic>?> getRandomQuestion() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'questions',
      orderBy: 'shown_count ASC, RANDOM()',
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  /// Mark question as solved (increment shown_count)
  /// This moves the question to the back of the queue
  Future<void> markQuestionAsSolved(int questionId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE questions SET shown_count = shown_count + 1 WHERE id = ?',
      [questionId],
    );
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

  /// Get all apps from dictionary
  Future<List<Map<String, dynamic>>> getAllApps() async {
    final db = await database;
    return await db.query('app_dictionary');
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
}
