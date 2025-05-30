import 'package:flutter/foundation.dart';
import 'ai_service.dart';

class PracticeService extends ChangeNotifier {
  int _totalExercises = 0;
  final AIService _aiService = AIService();

  // Renamed method to clarify it's for AI content only
  Future<Map<String, dynamic>> fetchAIContent() async {
    return await _aiService.generateSentence();
  }

  // Shared method to check answers
  bool checkAnswer(String userInput, String correctSentence) {
    // Normalize both strings for comparison
    final normalizedInput = _normalizeText(userInput);
    final normalizedCorrect = _normalizeText(correctSentence);

    return normalizedInput == normalizedCorrect;
  }

  // Helper method to normalize text for comparison
  String _normalizeText(String text) {
    // Restore any temporarily replaced periods before normalization
    String restored = text.replaceAll('###', '.');

    return restored
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), ''); // Remove punctuation
  }

  // Method to complete an exercise
  void completeExercise({String practiceType = 'general'}) {
    _totalExercises++;
    // Add any additional logic for tracking specific types of exercises
    notifyListeners(); // Notify listeners about the change
  }

  // Getter for total exercises
  int get totalExercises => _totalExercises;
}
