import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:focustalk_app/services/database_helper.dart';

class OverlayQuizScreen extends StatefulWidget {
  const OverlayQuizScreen({super.key});

  @override
  State<OverlayQuizScreen> createState() => _OverlayQuizScreenState();
}

class _OverlayQuizScreenState extends State<OverlayQuizScreen> {
  bool _isLoading = true;
  bool _isAnswered = false;
  Map<String, dynamic>? _questionData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
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

  void _handleAnswer(String selectedAnswer) {
    if (_questionData == null) return;

    final correctAnswer = _questionData!['correct_answer'] as String;

    if (selectedAnswer == correctAnswer) {
      // Correct answer - close overlay
      FlutterOverlayWindow.closeOverlay();
    } else {
      // Wrong answer - show feedback
      setState(() {
        _isAnswered = true;
      });

      // Reset after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
          });
        }
      });
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.95),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child:
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : _errorMessage != null
                    ? _buildErrorCard()
                    : _buildQuizCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => FlutterOverlayWindow.closeOverlay(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizCard() {
    final options = _getOptions();
    final optionLabels = ['A', 'B', 'C', 'D'];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[700],
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'FocusTalk Quiz',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAnswered ? null : () => _handleAnswer(option),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: Text(
                      '$label. $option',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Feedback message
            if (_isAnswered)
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
                      'Wrong! Try Again',
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
              'Answer correctly to continue using the app',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
