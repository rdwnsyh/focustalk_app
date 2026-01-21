import 'package:flutter/material.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PracticeQuizScreen extends StatefulWidget {
  const PracticeQuizScreen({super.key});

  @override
  State<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends State<PracticeQuizScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Map<String, dynamic>? _questionData;
  bool _isLoading = true;
  bool _isAnswered = false;
  String? _selectedAnswer;
  bool isCompleted = false; // NEW: Track if daily goal is completed

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
      // Check if already completed
      isCompleted = solved >= goal;
    });

    // Only load question if not completed
    if (!isCompleted) {
      _loadQuestion();
    }
  }

  /// Load a random question
  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _selectedAnswer = null;
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
          Navigator.pop(context);
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

  /// Handle answer selection
  Future<void> _handleAnswer(String selectedAnswer) async {
    if (_isAnswered || _questionData == null) return;

    final correctAnswer = _questionData!['correct_answer'] as String;

    setState(() {
      _isAnswered = true;
      _selectedAnswer = selectedAnswer;
    });

    if (selectedAnswer == correctAnswer) {
      // CORRECT ANSWER - Increment progress
      await _incrementProgress();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Correct! Loading next question...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }

      // Load next question after 1 second
      await Future.delayed(const Duration(seconds: 1));
      _loadQuestion();
    } else {
      // WRONG ANSWER - Show message, don't load new question
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Wrong answer! Try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Reset after 1 second so user can try again
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isAnswered = false;
        _selectedAnswer = null;
      });
    }
  }

  /// Increment solved count in SharedPreferences (same as background service)
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

    // Check if goal is met - immediately switch to completed state
    if (newCount >= _dailyGoal) {
      setState(() {
        isCompleted = true; // Switch to success view
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Practice Quiz'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purple,
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
                      ? _buildSuccessView() // Show success when completed
                      : _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.purple),
                      )
                      : _questionData == null
                      ? const Center(child: Text('No question available'))
                      : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Question Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _questionData!['question']?.toString() ??
                                    'Question not available',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Answer Options
                            ..._buildAnswerButtons(),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build answer option buttons
  List<Widget> _buildAnswerButtons() {
    if (_questionData == null) return [];

    final options = [
      _questionData!['option_a']?.toString() ?? 'Option A',
      _questionData!['option_b']?.toString() ?? 'Option B',
      _questionData!['option_c']?.toString() ?? 'Option C',
      _questionData!['option_d']?.toString() ?? 'Option D',
    ];

    final correctAnswer = _questionData!['correct_answer']?.toString() ?? '';

    return List.generate(options.length, (index) {
      final option = options[index];
      final optionLabel = String.fromCharCode(65 + index); // A, B, C, D

      // Determine button color
      Color buttonColor = Colors.white;
      Color textColor = Colors.black87;
      Color borderColor = Colors.grey.shade300;

      if (_isAnswered && _selectedAnswer == option) {
        if (option == correctAnswer) {
          buttonColor = Colors.green.shade50;
          borderColor = Colors.green;
          textColor = Colors.green.shade800;
        } else {
          buttonColor = Colors.red.shade50;
          borderColor = Colors.red;
          textColor = Colors.red.shade800;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: _isAnswered ? null : () => _handleAnswer(option),
          borderRadius: BorderRadius.circular(12),
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
                      optionLabel,
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
                    option?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
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
                Navigator.pop(context); // Return to home
              },
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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
