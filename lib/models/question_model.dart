/// Question Model for Quiz System
/// Matches the database schema in the questions table
class QuestionModel {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final int isSolved;

  QuestionModel({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    this.isSolved = 0,
  });

  /// Create QuestionModel from database map
  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as int,
      question: map['question'] as String,
      optionA: map['option_a'] as String,
      optionB: map['option_b'] as String,
      optionC: map['option_c'] as String,
      optionD: map['option_d'] as String,
      correctAnswer: map['correct_answer'] as String,
      isSolved: map['is_solved'] as int? ?? 0,
    );
  }

  /// Convert QuestionModel to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
      'is_solved': isSolved,
    };
  }

  /// Get list of options
  List<String> getOptions() {
    return [optionA, optionB, optionC, optionD];
  }

  /// Check if answer is correct
  bool isCorrectAnswer(String answer) {
    return answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }

  /// Create a copy with updated fields
  QuestionModel copyWith({
    int? id,
    String? question,
    String? optionA,
    String? optionB,
    String? optionC,
    String? optionD,
    String? correctAnswer,
    int? isSolved,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      optionA: optionA ?? this.optionA,
      optionB: optionB ?? this.optionB,
      optionC: optionC ?? this.optionC,
      optionD: optionD ?? this.optionD,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      isSolved: isSolved ?? this.isSolved,
    );
  }

  @override
  String toString() {
    return 'QuestionModel(id: $id, question: $question, correctAnswer: $correctAnswer, isSolved: $isSolved)';
  }
}
