import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:focustalk_app/controllers/overlay_quiz_controller.dart';

class OverlayQuizScreen extends StatelessWidget {
  const OverlayQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller using GetX
    final controller = Get.put(OverlayQuizController());

    return _OverlayQuizView();
  }
}

class _OverlayQuizView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OverlayQuizController>();
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
        backgroundColor: const Color(0xFFFFF3E0),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Obx(() {
                // STRICT LOADING STATE - Show loader until data is ready
                if (controller.isLoading.value) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: primaryOrange,
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Loading Question...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  );
                }

                // Error state
                if (controller.errorMessage.value != null) {
                  return _buildErrorCard(screenWidth, controller);
                }

                // Quiz UI - Only renders when data is fully loaded
                return _buildQuizCard(screenWidth, controller);
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(double screenWidth, OverlayQuizController controller) {
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
            controller.errorMessage.value!,
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

  Widget _buildQuizCard(double screenWidth, OverlayQuizController controller) {
    final options = controller.getOptions();
    final optionLabels = ['A', 'B', 'C', 'D'];
    const primaryOrange = Color(0xFFFF6B35);
    final correctAnswer = controller.getCorrectAnswer();

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
            controller.currentQuestion.value!['question'] as String,
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

            return Obx(() {
              final isSelected = controller.selectedOptionIndex.value == index;
              final isSubmitted = controller.isSubmitted.value;

              // ROBUST COMPARISON: Normalize strings for UI feedback
              final normalizedOption = option.trim().toLowerCase();
              final normalizedCorrect =
                  (correctAnswer ?? '').trim().toLowerCase();

              final isCorrectOption =
                  isSubmitted && normalizedOption == normalizedCorrect;
              final isWrongOption =
                  isSubmitted &&
                  isSelected &&
                  normalizedOption != normalizedCorrect;

              // Determine colors based on state
              Color borderColor;
              Color backgroundColor;
              Color textColor;

              if (isSubmitted) {
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
                  onTap:
                      isSubmitted ? null : () => controller.selectOption(index),
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
            });
          }),

          const SizedBox(height: 20),

          // Submit Button
          Obx(() {
            final canSubmit =
                controller.selectedOptionIndex.value != null &&
                !controller.isSubmitted.value;

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit ? controller.submitAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: canSubmit ? 4 : 0,
                ),
                child: Text(
                  controller.isSubmitted.value
                      ? 'Checking...'
                      : 'Submit Answer',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Feedback message
          Obx(() {
            if (controller.isSubmitted.value && controller.isAnswered.value) {
              // Wrong answer - show correct answer
              final correctAns = controller.getCorrectAnswer() ?? '';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: Colors.red[900], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Wrong Answer!',
                          style: TextStyle(
                            color: Colors.red[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Correct: ',
                            style: TextStyle(
                              color: Colors.green[900],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              correctAns,
                              style: TextStyle(
                                color: Colors.green[900],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Loading new question...',
                      style: TextStyle(color: Colors.red[700], fontSize: 11),
                    ),
                  ],
                ),
              );
            } else if (controller.isSubmitted.value &&
                !controller.isAnswered.value) {
              // Correct answer - show success feedback
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[900],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🎉 Correct! Well done!',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          const SizedBox(height: 12),

          // Info text
          Obx(() {
            return Text(
              controller.isSubmitted.value
                  ? 'Please wait...'
                  : 'Select an answer and tap Submit',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            );
          }),
        ],
      ),
    );
  }
}
