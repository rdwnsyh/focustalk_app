import 'package:flutter/material.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/screens/home_screen.dart';

class PracticeQuizScreen extends StatefulWidget {
  const PracticeQuizScreen({super.key});

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Map<String, dynamic>? _questionData;
  bool _isLoading = true;
  bool _isSubmitted = false;
  String? _selectedAnswer;
  bool? _isCorrect;
  bool isCompleted = false;

  int _solvedToday = 0;
  int _dailyGoal = 20;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  /// Load current progress from SharedPreferences
  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final solved = prefs.getInt('solved_today') ?? 0;
    final goal = prefs.getInt('daily_goal') ?? 20;

    setState(() {
      _solvedToday = solved;
      _dailyGoal = goal;
      isCompleted = solved >= goal;
    });

    // Only load question if not completed
    if (!isCompleted) {
      _loadQuestion();
    }
  }

  /// Load a random unsolved question
  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _isSubmitted = false;
      _selectedAnswer = null;
      _isCorrect = null;
    });

    try {
      final question = await _dbHelper.getRandomQuestion();

      if (question == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No questions available'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
        return;
      }

      setState(() {
        _questionData = question;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading question: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Handle answer selection (just select, don't validate yet)
  void _selectAnswer(String answer) {
    if (!_isSubmitted) {
      setState(() {
        _selectedAnswer = answer;
      });
    }
  }

  /// Handle answer submission (validate and mark)
  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _questionData == null) return;

    final correctAnswer = _questionData!['correct_answer'] as String;
    final questionId = _questionData!['id'] as int;
    final isCorrect = _selectedAnswer == correctAnswer;

    // Track stats
    await _dbHelper.updateStats(isCorrect);

    setState(() {
      _isSubmitted = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      // Correct answer - mark as solved
      await _dbHelper.markQuestionAsSolved(questionId);

      // Increment progress
      await _incrementProgress();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Correct! Great job!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// Load next question
  void _nextQuestion() {
    _loadQuestion();
  }

  /// Increment solved count in SharedPreferences
  Future<void> _incrementProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure we're on the correct day
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('last_solved_date', today);

    // Increment counter
    final currentCount = prefs.getInt('solved_today') ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt('solved_today', newCount);

    // Update local state
    setState(() {
      _solvedToday = newCount;
    });

    print('✅ Question solved! Progress: $newCount/$_dailyGoal');

    // Check if goal is met
    if (newCount >= _dailyGoal) {
      setState(() {
        isCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Practice Mode 🎯'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            ),
            tooltip: 'Quit Practice',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Solved Today',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_solvedToday / $_dailyGoal',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value:
                        _dailyGoal > 0
                            ? (_solvedToday / _dailyGoal).clamp(0.0, 1.0)
                            : 0.0,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            // Quiz Content or Success View
            Expanded(
              child:
                  isCompleted
                      ? _buildSuccessView()
                      : _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.deepOrange),
                      )
                      : _questionData == null
                      ? const Center(child: Text('No question available'))
                      : _buildQuizContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the quiz content with "Select First, Confirm Later" logic
  Widget _buildQuizContent() {
    final options = _getOptions();
    final optionLabels = ['A', 'B', 'C', 'D'];
    final correctAnswer = _questionData!['correct_answer'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _questionData!['question']?.toString() ?? 'Question not available',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Answer Options
          ...List.generate(options.length, (index) {
            final option = options[index];
            final label = optionLabels[index];
            final isSelected = _selectedAnswer == option;
            final isCorrectAnswer = option == correctAnswer;

            // Determine button styling based on state
            Color buttonColor = Colors.white;
            Color borderColor = Colors.grey[300]!;
            Color textColor = Colors.black87;

            if (_isSubmitted) {
              // After submission: highlight correct and show selected wrong
              if (isCorrectAnswer) {
                buttonColor = Colors.green[100]!;
                borderColor = Colors.green[600]!;
                textColor = Colors.green[900]!;
              } else if (isSelected && !isCorrectAnswer) {
                buttonColor = Colors.red[100]!;
                borderColor = Colors.red[600]!;
                textColor = Colors.red[900]!;
              }
            } else if (isSelected) {
              // Before submission: highlight selected
              buttonColor = Colors.blue[100]!;
              borderColor = Colors.blue[600]!;
              textColor = Colors.blue[900]!;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: _isSubmitted ? null : () => _selectAnswer(option),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: buttonColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: borderColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_isSubmitted && isCorrectAnswer)
                        Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                      if (_isSubmitted && isSelected && !isCorrectAnswer)
                        Icon(Icons.circle, color: Colors.red[700], size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Feedback message (after submission)
          if (_isSubmitted && !_isCorrect!)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[900], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The correct answer is: $correctAnswer',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_isSubmitted && _isCorrect!)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.green[900], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Great job! You got it right!',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Action Button (Check Answer / Next)
          ElevatedButton(
            onPressed: _selectedAnswer != null
                ? (_isSubmitted ? _nextQuestion : _submitAnswer)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSubmitted ? Colors.deepOrange : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey[400],
            ),
            child: Text(
              _isSubmitted ? 'Next Question' : 'Check Answer',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Info text
          Text(
            _isSubmitted
                ? (_isCorrect! ? 'Answer correctly to continue' : 'Try another question')
                : 'Select an answer above',
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

  /// Get options from question data
  List<String> _getOptions() {
    if (_questionData == null) return [];

    final options = <String>[];
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

  /// Build Success/Congratulation View when daily goal is reached
  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Trophy Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.emoji_events,
                size: 70,
                color: Colors.amber.shade700,
              ),
            ),

            const SizedBox(height: 32),

            // Success Title
            const Text(
              '🎉 Daily Target Reached!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Success Message
            Text(
              'You have completed $_dailyGoal questions today.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'You are now free from blocking!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Back to Home Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
