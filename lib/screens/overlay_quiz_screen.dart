import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OverlayQuizScreen extends StatefulWidget {
  const OverlayQuizScreen({super.key});

  @override
  State<OverlayQuizScreen> createState() => _OverlayQuizScreenState();
}

class _OverlayQuizScreenState extends State<OverlayQuizScreen> {
  final Stopwatch _focusTimer = Stopwatch();
  bool _isLoading = true;
  bool _isAnswered = false;
  Map<String, dynamic>? _questionData;
  String? _errorMessage;
  int? _selectedOptionIndex; // Track selected option (null = none selected)
  bool _isSubmitted = false; // Track if answer has been submitted

  @override
  void initState() {
    super.initState();
    _startFocusTimer();
    _loadQuestion();
  }

  @override
  void dispose() {
    _stopAndSaveFocusTime();
    super.dispose();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _errorMessage = null;
      _selectedOptionIndex = null; // Reset selection
      _isSubmitted = false; // Reset submit state
    });

    try {
      final dbHelper = DatabaseHelper();
      final question = await dbHelper.getRandomQuestion();

      setState(() {
        _questionData = question;
        _isLoading = false;
        if (question == null) {
          _errorMessage = 'No questions available in database';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading question: $e';
      });
    }
  }

  void _selectOption(int index) {
    if (_isSubmitted) return; // Can't change after submit
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _submitAnswer() async {
    if (_selectedOptionIndex == null || _isSubmitted) return;

    setState(() {
      _isSubmitted = true;
    });

    final options = _getOptions();
    final selectedAnswer = options[_selectedOptionIndex!];
    await _validateAnswer(selectedAnswer);
  }

  Future<void> _validateAnswer(String selectedAnswer) async {
    if (_questionData == null) return;

    final correctAnswer = _questionData!['correct_answer'] as String;
    final questionId = _questionData!['id'] as int;
    final isCorrect = selectedAnswer == correctAnswer;

    // Track stats (correct or wrong)
    final dbHelper = DatabaseHelper();
    await dbHelper.updateStats(isCorrect);

    if (isCorrect) {
      // Correct answer - mark as solved and INCREMENT daily progress
      await dbHelper.markQuestionAsSolved(questionId);

      // Increment solved count for daily goal tracking
      final goalMet = await dbHelper.incrementSolvedCount();

      // UPDATE STREAK: Claim streak for completing a quiz correctly
      await _updateStreak();

      // Show success feedback (green) for 1.5 seconds
      setState(() {
        _isAnswered = false; // Keep it false to show green state
      });

      await Future.delayed(const Duration(milliseconds: 1500));

      if (goalMet) {
        print('🎉 Daily goal achieved! Closing overlay - you are free today!');
        await _closeOverlayWithFocusSave();
      } else {
        print('✅ Correct answer! Granting 25 seconds access...');
        // Grant 25 seconds of temporary access
        await _grantRewardTime();
        // Close overlay - user can use app for 25 seconds
        await _closeOverlayWithFocusSave();
      }
    } else {
      // Wrong answer - show feedback and reset selection
      setState(() {
        _isAnswered = true;
      });

      // Show "Wrong Answer!" message for 1 second, then reset
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        // Reset selection and submission state to allow retry
        setState(() {
          _selectedOptionIndex = null;
          _isSubmitted = false;
          _isAnswered = false;
        });
      }
    }
  }

  void _startFocusTimer() {
    if (!_focusTimer.isRunning) {
      _focusTimer.start();
    }
  }

  Future<void> _stopAndSaveFocusTime() async {
    if (!_focusTimer.isRunning) {
      return;
    }

    _focusTimer.stop();
    final elapsedSeconds = _focusTimer.elapsed.inSeconds;
    _focusTimer.reset();

    if (elapsedSeconds <= 0) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final lastDate = prefs.getString('focus_time_date');

    if (lastDate != todayKey) {
      await prefs.setInt('focus_time_today', 0);
      await prefs.setString('focus_time_date', todayKey);
    }

    final current = prefs.getInt('focus_time_today') ?? 0;
    await prefs.setInt('focus_time_today', current + elapsedSeconds);
  }

  Future<void> _closeOverlayWithFocusSave() async {
    await _stopAndSaveFocusTime();
    FlutterOverlayWindow.closeOverlay();
  }

  /// Load a NEW random question from database
  /// This ensures we get a completely DIFFERENT question (No Duplicates)
  Future<void> _loadNewRandomQuestion() async {
    if (!mounted) return;

    // Capture the current question ID BEFORE fetching new one
    final oldQuestionId = _questionData?['id'] as int?;

    setState(() {
      _isLoading = true;
      _selectedOptionIndex = null; // Reset selection
      _isSubmitted = false; // Reset submit state
      _isAnswered = false; // Reset feedback
    });

    try {
      final dbHelper = DatabaseHelper();
      Map<String, dynamic>? newQuestion;

      if (oldQuestionId != null) {
        // Fetch a question EXCLUDING the current one (No Duplicate Logic)
        newQuestion = await dbHelper.getRandomQuestionExcluding(oldQuestionId);
        print('🔄 Loading new question (excluding ID: $oldQuestionId)');
      } else {
        // First question - no exclusion needed
        newQuestion = await dbHelper.getRandomQuestion();
        print('🔄 Loading first question');
      }

      if (mounted) {
        setState(() {
          _questionData = newQuestion;
          _isLoading = false;

          if (newQuestion == null) {
            _errorMessage = 'No questions available in database';
            print('❌ No questions found in database');
          } else {
            final newQuestionId = newQuestion['id'] as int;
            print(
              '✅ Question switched! Old ID: $oldQuestionId → New ID: $newQuestionId',
            );
            print('   Question: ${newQuestion['question']}');

            // Verify it's actually different
            if (oldQuestionId != null && oldQuestionId == newQuestionId) {
              print(
                '⚠️ WARNING: Same question appeared! This should not happen.',
              );
            }
          }
        });
      }
    } catch (e) {
      print('❌ Error loading new question: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading question: $e';
        });
      }
    }
  }

  /// Update streak when quiz is completed correctly
  Future<void> _updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get current streak data
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

        // Already claimed today - don't update
        if (last == today) {
          print('✅ Streak already claimed today');
          return;
        }

        // Check if continuing streak (yesterday)
        if (today.difference(last).inDays == 1) {
          currentStreak++;
          print('🔥 Streak continued! Now at $currentStreak days');
        } else {
          // Streak broken - reset to 1
          currentStreak = 1;
          weeklyStreak = List.filled(7, false);
          print('💔 Streak was broken. Starting fresh at 1 day');
        }
      } else {
        // First time - start streak
        currentStreak = 1;
        print('🆕 Starting new streak!');
      }

      // Mark today as active
      final weekdayIndex = today.weekday - 1; // Monday = 0
      weeklyStreak[weekdayIndex] = true;

      // Save to SharedPreferences
      await prefs.setInt('streak_count', currentStreak);
      await prefs.setString('last_streak_date', today.toIso8601String());
      await prefs.setString('weekly_streak', jsonEncode(weeklyStreak));

      print('✅ Streak updated: $currentStreak days');
    } catch (e) {
      print('❌ Error updating streak: $e');
    }
  }

  /// Grant 25-second temporary access for the current app
  Future<void> _grantRewardTime() async {
    try {
      // Get the package name from SharedPreferences (saved by background service)
      final prefs = await SharedPreferences.getInstance();
      final packageName = prefs.getString('current_blocked_app');

      if (packageName == null || packageName.isEmpty) {
        print('⚠️ Warning: Could not get package name for reward time');
        return;
      }

      // Calculate expiry timestamp (25 SECONDS from now)
      final expiryTime =
          DateTime.now()
              .add(const Duration(seconds: 25))
              .millisecondsSinceEpoch;

      // Save unlock expiry to SharedPreferences
      await prefs.setInt('unlock_expiry_$packageName', expiryTime);

      print('✅ App Unlocked for 25 seconds: $packageName');
      print('   Expiry: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
    } catch (e) {
      print('❌ Error granting reward time: $e');
    }
  }

  List<String> _getOptions() {
    if (_questionData == null) return [];

    final options = <String>[];

    // Add all available options
    if (_questionData!['option_a'] != null) {
      options.add(_questionData!['option_a'] as String);
    }
    if (_questionData!['option_b'] != null) {
      options.add(_questionData!['option_b'] as String);
    }
    if (_questionData!['option_c'] != null) {
      options.add(_questionData!['option_c'] as String);
    }
    if (_questionData!['option_d'] != null) {
      options.add(_questionData!['option_d'] as String);
    }

    return options;
  }

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF6B35);
    final screenWidth = MediaQuery.of(context).size.width;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryOrange,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryOrange,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF3E0),
      ),
      home: Scaffold(
        backgroundColor: const Color(
          0xFFFFF3E0,
        ), // Soft Cream/Orange Tint - SOLID
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(
                        color: primaryOrange,
                        strokeWidth: 4,
                      )
                      : _errorMessage != null
                      ? _buildErrorCard(screenWidth)
                      : _buildQuizCard(screenWidth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(double screenWidth) {
    const primaryOrange = Color(0xFFFF6B35);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => FlutterOverlayWindow.closeOverlay(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(double screenWidth) {
    final options = _getOptions();
    final optionLabels = ['A', 'B', 'C', 'D'];
    const primaryOrange = Color(0xFFFF6B35);
    final correctAnswer = _questionData!['correct_answer'] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - Lock Icon & Title
          const Icon(Icons.lock_person, color: primaryOrange, size: 48),
          const SizedBox(height: 12),
          Text(
            'Focus Mode Active',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Answer correctly to unlock',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),

          const SizedBox(height: 32),

          // Question
          Text(
            _questionData!['question'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          // Answer Options
          ...List.generate(options.length, (index) {
            final option = options[index];
            final label = optionLabels[index];
            final isSelected = _selectedOptionIndex == index;
            final isCorrectOption = _isSubmitted && option == correctAnswer;
            final isWrongOption =
                _isSubmitted && isSelected && option != correctAnswer;

            // Determine colors based on state
            Color borderColor;
            Color backgroundColor;
            Color textColor;

            if (_isSubmitted) {
              // After submit: Show correct/wrong
              if (isCorrectOption) {
                borderColor = Colors.green;
                backgroundColor = Colors.green.withOpacity(0.1);
                textColor = Colors.green[900]!;
              } else if (isWrongOption) {
                borderColor = Colors.red;
                backgroundColor = Colors.red.withOpacity(0.1);
                textColor = Colors.red[900]!;
              } else {
                borderColor = Colors.grey[300]!;
                backgroundColor = Colors.white;
                textColor = Colors.grey[600]!;
              }
            } else {
              // Before submit: Show selection
              if (isSelected) {
                borderColor = primaryOrange;
                backgroundColor = primaryOrange.withOpacity(0.1);
                textColor = primaryOrange;
              } else {
                borderColor = Colors.grey[300]!;
                backgroundColor = Colors.white;
                textColor = Colors.black87;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: _isSubmitted ? null : () => _selectOption(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(
                      color: borderColor,
                      width:
                          isSelected || isCorrectOption || isWrongOption
                              ? 2.5
                              : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Option Icon
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color:
                              isSelected || isCorrectOption
                                  ? borderColor
                                  : Colors.transparent,
                          border: Border.all(color: borderColor, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected || isCorrectOption
                                      ? Colors.white
                                      : borderColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Option Text
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      // Checkmark for correct answer
                      if (isCorrectOption)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      // X mark for wrong answer
                      if (isWrongOption)
                        const Icon(Icons.cancel, color: Colors.red, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _selectedOptionIndex == null || _isSubmitted
                      ? null
                      : _submitAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _selectedOptionIndex != null ? 4 : 0,
              ),
              child: Text(
                _isSubmitted ? 'Checking...' : 'Submit Answer',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Feedback message
          if (_isSubmitted && _isAnswered)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.close, color: Colors.red[900], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Wrong! Loading new question...',
                    style: TextStyle(
                      color: Colors.red[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Info text
          Text(
            _isSubmitted ? 'Please wait...' : 'Select an answer and tap Submit',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
