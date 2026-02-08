import 'dart:convert';
import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayQuizController extends GetxController {
  // Observable state
  final isLoading = true.obs;
  final isAnswered = false.obs;
  final isSubmitted = false.obs;
  final selectedOptionIndex = Rx<int?>(null);
  final currentQuestion = Rx<Map<String, dynamic>?>(null);
  final errorMessage = Rx<String?>(null);

  // Safety mechanism: Periodic validation timer
  Timer? _validationTimer;

  @override
  void onInit() {
    super.onInit();
    print('═══════════════════════════════════════════════════════');
    print('🟢 OVERLAY ISOLATE: OverlayQuizController.onInit() called');
    print('🟢 OVERLAY ISOLATE: Controller may be REUSED by Flutter Engine');
    print('═══════════════════════════════════════════════════════');

    // Start periodic validation (checks every 2 seconds)
    _startPeriodicValidation();

    // Validate and load question
    validateCurrentQuestion();
  }

  @override
  void onReady() {
    super.onReady();
    print('🟢 OVERLAY ISOLATE: onReady() called - Running validation');
    // Extra safety check when widget is ready
    validateCurrentQuestion();
  }

  @override
  void onClose() {
    // Clean up timer when controller is disposed
    _validationTimer?.cancel();
    print('🟢 OVERLAY ISOLATE: Controller disposed, timer cancelled');
    super.onClose();
  }

  /// Start periodic validation to detect stale questions
  /// This is a safety net for when the controller is reused
  void _startPeriodicValidation() {
    _validationTimer?.cancel(); // Cancel any existing timer

    _validationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // Only validate if not currently loading and not submitted
      if (!isLoading.value &&
          !isSubmitted.value &&
          currentQuestion.value != null) {
        print('⏰ PERIODIC CHECK: Running background validation...');
        validateCurrentQuestion();
      }
    });

    print('✅ PERIODIC VALIDATION: Started (checks every 3 seconds)');
  }

  /// Validate current question - if it's solved or null, load a new one
  /// This handles the case where Flutter Engine reuses the controller
  Future<void> validateCurrentQuestion() async {
    print('🔍 VALIDATION: Checking if current question needs refresh...');

    if (currentQuestion.value == null) {
      print('🔍 VALIDATION: No current question - loading new one');
      await loadAsyncData();
      return;
    }

    // Check if current question is already solved
    final questionId = currentQuestion.value!['id'] as int;
    print('🔍 VALIDATION: Current question ID: $questionId');

    final dbHelper = DatabaseHelper();
    final isSolved = await dbHelper.isQuestionSolved(questionId);

    if (isSolved) {
      print('⚠️ VALIDATION: Question $questionId is ALREADY SOLVED!');
      print('⚠️ VALIDATION: Controller was REUSED - loading fresh question...');
      await loadAsyncData();
    } else {
      print(
        '✅ VALIDATION: Question $questionId is still unsolved - keeping it',
      );
    }
  }

  /// Load question from database (uses is_solved column for tracking)
  Future<void> loadAsyncData() async {
    try {
      // STEP 1: Set loading state
      isLoading.value = true;
      errorMessage.value = null;
      selectedOptionIndex.value = null;
      isSubmitted.value = false;
      isAnswered.value = false;
      print('� OVERLAY ISOLATE: loadAsyncData() started');
      print('🟢 OVERLAY ISOLATE: Loading NEW unsolved question...');

      // STEP 2: Get database instance and verify connection
      final dbHelper = DatabaseHelper();
      print('🟢 OVERLAY ISOLATE: DatabaseHelper instance obtained');

      // Verify database is accessible
      final db = await dbHelper.database;
      print('🟢 OVERLAY ISOLATE: Database connection verified');
      print('🟢 OVERLAY ISOLATE: DB Path: ${db.path}');

      // Get random unsolved question
      print('🟢 OVERLAY ISOLATE: Fetching random unsolved question...');
      final question = await dbHelper.getRandomUnsolvedQuestion();

      if (question == null) {
        errorMessage.value = 'No questions available in database';
        isLoading.value = false;
        print('❌ OVERLAY ISOLATE: No questions found in database');
        return;
      }

      // STEP 3: Assign question to state
      currentQuestion.value = question;
      final questionId = question['id'];
      final questionText = question['question'].toString();
      final correctAns = question['correct_answer'];
      final isSolved = question['is_solved'];

      print('╔════════════════════════════════════════════════════════');
      print('║ 🟢 OVERLAY ISOLATE: QUESTION LOADED');
      print('║ Question ID: $questionId');
      print('║ is_solved: $isSolved (should be 0)');
      print('║ Question: $questionText');
      print('║ Correct Answer: $correctAns');
      print('╚════════════════════════════════════════════════════════');

      // STEP 4: Allow UI to render
      isLoading.value = false;
      print('🟢 OVERLAY ISOLATE: Question ready for display');
    } catch (e, stackTrace) {
      print('❌ OVERLAY ISOLATE: Error loading question: $e');
      print('❌ OVERLAY ISOLATE: Stack trace: $stackTrace');
      errorMessage.value = 'Failed to load question: $e';
      isLoading.value = false;
    }
  }

  /// Load next question (used after wrong answer)
  Future<void> loadNextQuestion() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      selectedOptionIndex.value = null;
      isSubmitted.value = false;
      isAnswered.value = false;
      print('🔄 Loading next question after wrong answer...');

      // Get another random unsolved question
      final dbHelper = DatabaseHelper();
      final question = await dbHelper.getRandomUnsolvedQuestion();

      if (question == null) {
        errorMessage.value = 'No questions available';
        isLoading.value = false;
        return;
      }

      currentQuestion.value = question;
      isLoading.value = false;
      print('✅ New question loaded: ID ${question['id']}');
    } catch (e) {
      print('❌ Error loading next question: $e');
      errorMessage.value = 'Error loading question: $e';
      isLoading.value = false;
    }
  }

  /// Select an option (before submission)
  void selectOption(int index) {
    if (isSubmitted.value) return; // Can't change after submit
    selectedOptionIndex.value = index;
    print('👆 Selected option: $index');
  }

  /// Submit the selected answer (THE TRIGGER)
  Future<void> submitAnswer() async {
    if (selectedOptionIndex.value == null || isSubmitted.value) {
      print('⚠️ Cannot submit: No option selected or already submitted');
      return;
    }

    isSubmitted.value = true;

    final options = getOptions();
    final selectedAnswer = options[selectedOptionIndex.value!];
    await _validateAnswer(selectedAnswer);
  }

  /// Validate the answer and handle result (ROBUST VERSION)
  Future<void> _validateAnswer(String selectedAnswer) async {
    if (currentQuestion.value == null) return;

    final correctAnswer = currentQuestion.value!['correct_answer'] as String;
    final questionId = currentQuestion.value!['id'] as int;

    // ========================================
    // ROBUST STRING NORMALIZATION
    // ========================================
    // Step 1: Normalize both strings (trim + lowercase)
    final normalizedSelected = selectedAnswer.trim().toLowerCase();
    final normalizedCorrect = correctAnswer.trim().toLowerCase();

    // Step 2: Primary comparison with normalized strings
    bool isCorrect = normalizedSelected == normalizedCorrect;

    // Step 3: Fallback - Check if correct_answer is an option key (A, B, C, D)
    if (!isCorrect && ['a', 'b', 'c', 'd'].contains(normalizedCorrect)) {
      // Handle case where database stores 'A', 'B', 'C', 'D' instead of full text
      final options = getOptions();
      final optionIndex =
          normalizedCorrect == 'a'
              ? 0
              : normalizedCorrect == 'b'
              ? 1
              : normalizedCorrect == 'c'
              ? 2
              : 3;

      if (optionIndex < options.length) {
        final actualCorrectAnswer = options[optionIndex].trim().toLowerCase();
        isCorrect = normalizedSelected == actualCorrectAnswer;
        print(
          '🔄 Fallback check: Option key "$correctAnswer" -> Actual text "${options[optionIndex]}"',
        );
      }
    }

    // ========================================
    // DEBUG PRINTS (DETAILED COMPARISON LOG)
    // ========================================
    print('═══════════════════════════════════════════════════════');
    print('📋 ANSWER VALIDATION DEBUG:');
    print('   Question ID: $questionId');
    print('   User selected (RAW): "$selectedAnswer"');
    print('   User selected (NORMALIZED): "$normalizedSelected"');
    print('   Correct answer (RAW): "$correctAnswer"');
    print('   Correct answer (NORMALIZED): "$normalizedCorrect"');
    print('   Comparison result: ${isCorrect ? '✅ CORRECT' : '❌ WRONG'}');
    if (!isCorrect) {
      print('   ⚠️ Expected: "$correctAnswer"');
      print('   ⚠️ Got: "$selectedAnswer"');
    }
    print('═══════════════════════════════════════════════════════');

    // Track stats
    final dbHelper = DatabaseHelper();
    await dbHelper.updateStats(isCorrect);

    if (isCorrect) {
      // ✅ CORRECT ANSWER PATH
      print('╔════════════════════════════════════════════════════════');
      print('║ 🟢 OVERLAY ISOLATE: CORRECT ANSWER!');
      print('║ Question ID: $questionId');
      print('╚════════════════════════════════════════════════════════');

      // CRITICAL: Mark question as solved FIRST, before any other operations
      print('🟢 OVERLAY ISOLATE: Step 1/4: Marking question as solved...');
      await dbHelper.markQuestionAsSolved(questionId);

      // Verify the question was marked
      final db = await dbHelper.database;
      final verify = await db.rawQuery(
        'SELECT id, is_solved FROM questions WHERE id = ?',
        [questionId],
      );
      if (verify.isNotEmpty) {
        final status = verify.first['is_solved'];
        print('🟢 OVERLAY ISOLATE: Verification - is_solved = $status');
        if (status == 1) {
          print('✅ OVERLAY ISOLATE: Question $questionId VERIFIED as solved');
        } else {
          print(
            '⚠️ OVERLAY ISOLATE: WARNING - Question not marked! is_solved = $status',
          );
        }
      }

      // Add small delay to ensure database write is flushed
      await Future.delayed(const Duration(milliseconds: 100));
      print('✅ OVERLAY ISOLATE: Step 1/4: Question marked as solved');

      // Update daily progress
      print('🟢 OVERLAY ISOLATE: Step 2/4: Updating daily progress...');
      final goalMet = await dbHelper.incrementSolvedCount();
      print('✅ OVERLAY ISOLATE: Step 2/4: Daily progress updated');

      // Update streak
      print('🟢 OVERLAY ISOLATE: Step 3/4: Updating streak...');
      await _updateStreak();
      print('✅ OVERLAY ISOLATE: Step 3/4: Streak updated');

      // Grant reward time
      print('🟢 OVERLAY ISOLATE: Step 4/4: Granting reward time...');
      if (goalMet) {
        print('🎉 OVERLAY ISOLATE: Daily goal achieved! User is free today!');
      } else {
        print('⏱️ OVERLAY ISOLATE: Granting 25 seconds access...');
        await _grantRewardTime();
      }
      print('✅ OVERLAY ISOLATE: Step 4/4: Reward granted');

      // Show success feedback
      isAnswered.value = false; // Keep false to show green state
      print('🟢 OVERLAY ISOLATE: Showing success feedback...');

      // CRITICAL: PRE-FETCH next question BEFORE closing overlay
      // This prepares the controller for reuse by Flutter Engine
      print('🔄 PRE-FETCH: Loading next question in background...');

      // Start loading next question in parallel with success animation
      final nextQuestionFuture = loadAsyncData();

      // Show success animation
      await Future.delayed(const Duration(milliseconds: 1500));

      // Ensure next question is loaded
      await nextQuestionFuture;
      print('✅ PRE-FETCH: Next question ready for when overlay reopens');

      // Close overlay (next question is ALREADY loaded in memory)
      print('╔════════════════════════════════════════════════════════');
      print('║ 🚪 OVERLAY ISOLATE: CLOSING OVERLAY');
      print('║ Question $questionId is now IN DATABASE as SOLVED');
      print('║ NEW question is PRE-LOADED in controller memory');
      print('║ When overlay reopens, validation will use cached question');
      print('╚════════════════════════════════════════════════════════');
      FlutterOverlayWindow.closeOverlay();
      print('╚════════════════════════════════════════════════════════');
      FlutterOverlayWindow.closeOverlay();
    } else {
      // ❌ WRONG ANSWER PATH
      print('❌ WRONG ANSWER! Loading new question...');
      print('   💡 The correct answer was: "$correctAnswer"');

      // Show error feedback
      isAnswered.value = true;
      await Future.delayed(const Duration(milliseconds: 1500));

      // Load a NEW question immediately
      await loadNextQuestion();
    }
  }

  /// Update streak when quiz is completed correctly
  Future<void> _updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int currentStreak = prefs.getInt('streak_count') ?? 0;
      final lastDateStr = prefs.getString('last_streak_date');
      List<bool> weeklyStreak = List.filled(7, false);
      final weeklyStr = prefs.getString('weekly_streak');
      if (weeklyStr != null) {
        weeklyStreak = List<bool>.from(jsonDecode(weeklyStr));
      }

      DateTime? lastDate;
      if (lastDateStr != null) {
        lastDate = DateTime.parse(lastDateStr);
      }

      if (lastDate != null) {
        final last = DateTime(lastDate.year, lastDate.month, lastDate.day);

        if (last == today) {
          print('✅ Streak already claimed today');
          return;
        }

        if (today.difference(last).inDays == 1) {
          currentStreak++;
          print('🔥 Streak continued! Now at $currentStreak days');
        } else {
          currentStreak = 1;
          weeklyStreak = List.filled(7, false);
          print('💔 Streak broken. Starting fresh at 1 day');
        }
      } else {
        currentStreak = 1;
        print('🆕 Starting new streak!');
      }

      final weekdayIndex = today.weekday - 1;
      weeklyStreak[weekdayIndex] = true;

      await prefs.setInt('streak_count', currentStreak);
      await prefs.setString('last_streak_date', today.toIso8601String());
      await prefs.setString('weekly_streak', jsonEncode(weeklyStreak));

      print('✅ Streak updated: $currentStreak days');
    } catch (e) {
      print('❌ Error updating streak: $e');
    }
  }

  /// Grant 25-second temporary access
  Future<void> _grantRewardTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageName = prefs.getString('current_blocked_app');

      if (packageName == null || packageName.isEmpty) {
        print('⚠️ Warning: Could not get package name for reward time');
        return;
      }

      final expiryTime =
          DateTime.now()
              .add(const Duration(seconds: 25))
              .millisecondsSinceEpoch;

      await prefs.setInt('unlock_expiry_$packageName', expiryTime);

      print('✅ Unlocked $packageName for 25 seconds');
      print('   Expiry: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
    } catch (e) {
      print('❌ Error granting reward time: $e');
    }
  }

  /// Get options for current question
  List<String> getOptions() {
    if (currentQuestion.value == null) return [];

    final q = currentQuestion.value!;
    final options = <String>[];

    if (q['option_a'] != null) options.add(q['option_a'] as String);
    if (q['option_b'] != null) options.add(q['option_b'] as String);
    if (q['option_c'] != null) options.add(q['option_c'] as String);
    if (q['option_d'] != null) options.add(q['option_d'] as String);

    return options;
  }

  /// Get correct answer for current question
  String? getCorrectAnswer() {
    return currentQuestion.value?['correct_answer'] as String?;
  }
}
