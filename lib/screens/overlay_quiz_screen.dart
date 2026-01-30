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
  bool _isLoading = true;
  bool _isSubmitted = false;
  String? _selectedAnswer;
  bool? _isCorrect;
  Map<String, dynamic>? _questionData;
  String? _errorMessage;

  // -- Warna Tema Modern --
  final Color _primaryColor = const Color(0xFF6366F1); // Indigo Modern
  final Color _correctColor = const Color(0xFF10B981); // Emerald Green
  final Color _wrongColor = const Color(0xFFEF4444); // Rose Red
  final Color _neutralColor = const Color(0xFFF3F4F6); // Light Grey
  final Color _textColor = const Color(0xFF1F2937); // Dark Grey Text

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _isLoading = true;
      _isSubmitted = false;
      _selectedAnswer = null;
      _isCorrect = null;
      _errorMessage = null;
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
    final dbHelper = DatabaseHelper();
    await dbHelper.updateStats(isCorrect);

    setState(() {
      _isSubmitted = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      // Correct answer - mark as solved and INCREMENT daily progress
      await dbHelper.markQuestionAsSolved(questionId);

      // Increment solved count for daily goal tracking
      final goalMet = await dbHelper.incrementSolvedCount();

      if (goalMet) {
        print('🎉 Daily goal achieved! Closing overlay - you are free today!');
        // Auto-close after 1 second to let user see the success message
        Future.delayed(const Duration(seconds: 1), () {
          FlutterOverlayWindow.closeOverlay();
        });
      } else {
        print('✅ Correct answer! Progress updated.');
      }
    }
  }

  /// Load next question
  void _nextQuestion() {
    _loadQuestion();
  }

  /// Grant 7-second reward time for the current app (DEMO)
  Future<void> _grantRewardTime() async {
    try {
      // Get the package name from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final packageName = prefs.getString('current_blocked_app');

      if (packageName == null || packageName.isEmpty) {
        print('⚠️ Warning: Could not get package name for reward time');
        return;
      }

      // Calculate expiry timestamp (7 SECONDS from now for DEMO)
      final expiryTime =
          DateTime.now().add(const Duration(seconds: 7)).millisecondsSinceEpoch;

      // Save unlock expiry to SharedPreferences
      await prefs.setInt('unlock_expiry_$packageName', expiryTime);

      print('✅ App Unlocked for 7 seconds: $packageName');
    } catch (e) {
      print('❌ Error granting reward time: $e');
    }
  }

  List<String> _getOptions() {
    if (_questionData == null) return [];

    final options = <String>[];
    if (_questionData!['option_a'] != null) options.add(_questionData!['option_a'] as String);
    if (_questionData!['option_b'] != null) options.add(_questionData!['option_b'] as String);
    if (_questionData!['option_c'] != null) options.add(_questionData!['option_c'] as String);
    if (_questionData!['option_d'] != null) options.add(_questionData!['option_d'] as String);

    return options;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto', // Menggunakan font default yang bersih
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent, // Transparan agar terlihat overlay
        body: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85), // Latar belakang dimming yang lebih smooth
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _errorMessage != null
                      ? _buildErrorCard()
                      : _buildQuizCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 10,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: _wrongColor, size: 64),
            const SizedBox(height: 16),
            Text(
              "Oops!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => FlutterOverlayWindow.closeOverlay(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _wrongColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard() {
    final options = _getOptions();
    final optionLabels = ['A', 'B', 'C', 'D'];
    final correctAnswer = _questionData!['correct_answer'] as String;

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- HEADER: Status Bar ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: _isCorrect == null
                  ? _primaryColor
                  : _isCorrect!
                      ? _correctColor
                      : _wrongColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCorrect == null
                      ? Icons.lightbulb_circle
                      : _isCorrect!
                          ? Icons.check_circle
                          : Icons.cancel,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _isCorrect == null
                      ? 'FocusTalk Quiz'
                      : _isCorrect!
                          ? 'Correct Answer!'
                          : 'Wrong Answer',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                // --- Question Text ---
                Text(
                  _questionData!['question'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // --- Options List ---
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final label = optionLabels[index];
                    final isSelected = _selectedAnswer == option;
                    final isCorrectAnswer = option == correctAnswer;

                    // Determine Colors
                    Color bgColor = Colors.white;
                    Color borderColor = Colors.grey[300]!;
                    Color labelColor = _textColor;
                    FontWeight fontWeight = FontWeight.normal;

                    if (_isSubmitted) {
                      if (isCorrectAnswer) {
                        bgColor = _correctColor.withOpacity(0.1);
                        borderColor = _correctColor;
                        labelColor = _correctColor; // Text jadi hijau
                        fontWeight = FontWeight.bold;
                      } else if (isSelected && !isCorrectAnswer) {
                        bgColor = _wrongColor.withOpacity(0.1);
                        borderColor = _wrongColor;
                        labelColor = _wrongColor; // Text jadi merah
                      }
                    } else if (isSelected) {
                      bgColor = _primaryColor.withOpacity(0.08);
                      borderColor = _primaryColor;
                      labelColor = _primaryColor;
                      fontWeight = FontWeight.bold;
                    }

                    return InkWell(
                      onTap: _isSubmitted ? null : () => _selectAnswer(option),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(color: borderColor, width: isSelected || (_isSubmitted && isCorrectAnswer) ? 2 : 1.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Option Label (A, B, C, D) Badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected || (_isSubmitted && isCorrectAnswer) ? labelColor : Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected || (_isSubmitted && isCorrectAnswer) ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
                                  color: Colors.black87,
                                  fontWeight: fontWeight,
                                ),
                              ),
                            ),
                            // Status Icon
                            if (_isSubmitted && isCorrectAnswer)
                              Icon(Icons.check_circle, color: _correctColor),
                            if (_isSubmitted && isSelected && !isCorrectAnswer)
                              Icon(Icons.cancel, color: _wrongColor),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // --- Feedback Message Area ---
                if (_isSubmitted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isCorrect! ? _correctColor.withOpacity(0.1) : _wrongColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isCorrect! ? _correctColor.withOpacity(0.3) : _wrongColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                         Icon(
                           _isCorrect! ? Icons.celebration_rounded : Icons.info_outline_rounded,
                           color: _isCorrect! ? _correctColor : _wrongColor
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 _isCorrect! ? 'Great Job!' : 'Incorrect Answer',
                                 style: TextStyle(
                                   fontWeight: FontWeight.bold,
                                   color: _isCorrect! ? _correctColor : _wrongColor,
                                 ),
                               ),
                               if (!_isCorrect!)
                                 Text(
                                   'Correct answer: $correctAnswer',
                                   style: TextStyle(
                                     fontSize: 13,
                                     color: Colors.grey[800],
                                   ),
                                 ),
                             ],
                           ),
                         )
                      ],
                    ),
                  ),

                // --- Action Button ---
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _selectedAnswer != null
                        ? (_isSubmitted ? _nextQuestion : _submitAnswer)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubmitted ? Colors.orange.shade600 : _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: (_isSubmitted ? Colors.orange : _primaryColor).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[500],
                    ),
                    child: Text(
                      _isSubmitted ? 'Next Question' : 'Check Answer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                // --- Footer Hint ---
                const SizedBox(height: 16),
                Text(
                   _isSubmitted
                      ? (_isCorrect! ? 'Keep going to unlock your apps!' : 'Don\'t give up!')
                      : 'Select an option to continue',
                   style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}