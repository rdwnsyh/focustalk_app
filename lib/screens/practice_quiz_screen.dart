import 'package:flutter/material.dart';
import 'package:focustalk_app/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focustalk_app/screens/main_screen.dart';

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

  // --- PALET WARNA (Sesuai Request) ---
  final Color _colOrange = const Color(0xFFFF7043); // Modern Orange
  final Color _colRed = const Color(0xFFEF5350); // Soft Red
  final Color _colGreen = const Color(
    0xFF66BB6A,
  ); // Soft Green (Wajib untuk quiz benar)
  final Color _bgGrey = const Color(0xFFF4F6F8); // Cool Grey Background
  final Color _textDark = const Color(0xFF263238); // Dark Blue-Grey Text
  final Color _textGrey = const Color(0xFF78909C); // Light Grey Text

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

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

    if (!isCompleted) {
      _loadQuestion();
    }
  }

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
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
        return;
      }

      setState(() {
        _questionData = question;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _selectAnswer(String answer) {
    if (!_isSubmitted) {
      setState(() {
        _selectedAnswer = answer;
      });
    }
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null || _questionData == null) return;

    final correctAnswer = _questionData!['correct_answer'] as String;
    final questionId = _questionData!['id'] as int;
    final isCorrect = _selectedAnswer == correctAnswer;

    await _dbHelper.updateStats(isCorrect);

    setState(() {
      _isSubmitted = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      await _dbHelper.markQuestionAsSolved(questionId);
      await _incrementProgress();
    }
  }

  void _nextQuestion() {
    _loadQuestion();
  }

  Future<void> _incrementProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('last_solved_date', today);

    final currentCount = prefs.getInt('solved_today') ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt('solved_today', newCount);

    setState(() {
      _solvedToday = newCount;
    });

    if (newCount >= _dailyGoal) {
      setState(() {
        isCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      body: SafeArea(
        child: Column(
          children: [
            // ================= CUSTOM HEADER =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice Quiz',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                          Text(
                            'Keep focusing!',
                            style: TextStyle(fontSize: 12, color: _textGrey),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed:
                            () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(),
                              ),
                            ),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 20, color: _textDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Goal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textGrey,
                        ),
                      ),
                      Text(
                        '$_solvedToday/$_dailyGoal',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _colOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value:
                          _dailyGoal > 0
                              ? (_solvedToday / _dailyGoal).clamp(0.0, 1.0)
                              : 0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(_colOrange),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),

            // ================= MAIN QUIZ CONTENT =================
            Expanded(
              child:
                  isCompleted
                      ? _buildSuccessView()
                      : _isLoading
                      ? Center(
                        child: CircularProgressIndicator(color: _colOrange),
                      )
                      : _questionData == null
                      ? const Center(child: Text('No question available'))
                      : _buildQuizBody(),
            ),
          ],
        ),
      ),
    );
  }

  /// The main scrollable body of the quiz
  Widget _buildQuizBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Card
          Text(
            'QUESTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _textGrey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _questionData!['question']?.toString() ?? '',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),

          // Options List
          ..._buildOptionsList(),

          const SizedBox(height: 24),

          // Feedback & Button Area
          _buildBottomActions(),
        ],
      ),
    );
  }

  List<Widget> _buildOptionsList() {
    final options = _getOptions();
    final optionLabels = ['A', 'B', 'C', 'D'];
    final correctAnswer = _questionData!['correct_answer'] as String;

    return List.generate(options.length, (index) {
      final option = options[index];
      final label = optionLabels[index];
      final isSelected = _selectedAnswer == option;
      final isCorrectAnswer = option == correctAnswer;

      // Styling Logic
      Color bgColor = Colors.white;
      Color borderColor = Colors.transparent;
      Color textColor = _textDark;
      Color labelBg = Colors.grey.shade100;
      Color labelText = _textGrey;

      if (_isSubmitted) {
        if (isCorrectAnswer) {
          // Benar -> Hijau (Green is standard for Correct)
          bgColor = _colGreen.withOpacity(0.1);
          borderColor = _colGreen;
          textColor = Colors.green.shade800;
          labelBg = _colGreen;
          labelText = Colors.white;
        } else if (isSelected && !isCorrectAnswer) {
          // Salah -> Merah
          bgColor = _colRed.withOpacity(0.1);
          borderColor = _colRed;
          textColor = _colRed;
          labelBg = _colRed;
          labelText = Colors.white;
        } else {
          // Tidak dipilih -> Redup
          bgColor = Colors.white.withOpacity(0.5);
          textColor = Colors.grey.shade400;
        }
      } else {
        // Belum Submit
        if (isSelected) {
          // Terpilih -> Oranye
          bgColor = _colOrange.withOpacity(0.1);
          borderColor = _colOrange;
          textColor = _colOrange;
          labelBg = _colOrange;
          labelText = Colors.white;
        } else {
          // Normal -> Putih
          bgColor = Colors.white;
          borderColor = Colors.grey.shade200;
        }
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: _isSubmitted ? null : () => _selectAnswer(option),
          borderRadius: BorderRadius.circular(16),
          splashColor: _colOrange.withOpacity(0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow:
                  isSelected && !_isSubmitted
                      ? [
                        BoxShadow(
                          color: _colOrange.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
            ),
            child: Row(
              children: [
                // Label Circle (A,B,C,D)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: labelBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: labelText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Option Text
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                // Icon Status
                if (_isSubmitted && isCorrectAnswer)
                  Icon(Icons.check_circle_rounded, color: _colGreen, size: 24),
                if (_isSubmitted && isSelected && !isCorrectAnswer)
                  Icon(Icons.cancel_rounded, color: _colRed, size: 24),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBottomActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Feedback Message Container
        if (_isSubmitted)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  _isCorrect!
                      ? _colGreen.withOpacity(0.1)
                      : _colRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isCorrect!
                        ? _colGreen.withOpacity(0.3)
                        : _colRed.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isCorrect!
                      ? Icons.sentiment_very_satisfied
                      : Icons.sentiment_dissatisfied,
                  color: _isCorrect! ? Colors.green.shade700 : _colRed,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCorrect! ? 'Correct Answer!' : 'Incorrect',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isCorrect! ? Colors.green.shade800 : _colRed,
                        ),
                      ),
                      if (!_isCorrect!)
                        Text(
                          'Correct: ${_questionData!['correct_answer']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Main Action Button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed:
                _selectedAnswer != null
                    ? (_isSubmitted ? _nextQuestion : _submitAnswer)
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _colOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _isSubmitted ? 'Next Question' : 'Check Answer',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getOptions() {
    if (_questionData == null) return [];
    final options = <String>[];
    if (_questionData!['option_a'] != null)
      options.add(_questionData!['option_a'] as String);
    if (_questionData!['option_b'] != null)
      options.add(_questionData!['option_b'] as String);
    if (_questionData!['option_c'] != null)
      options.add(_questionData!['option_c'] as String);
    if (_questionData!['option_d'] != null)
      options.add(_questionData!['option_d'] as String);
    return options;
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _colOrange.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.star_rounded, size: 80, color: _colOrange),
            ),
            const SizedBox(height: 32),
            Text(
              'Goal Achieved!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You solved $_dailyGoal questions today.\nBlocking is now disabled. Great job!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: _textGrey, height: 1.5),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.home_rounded),
                label: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
