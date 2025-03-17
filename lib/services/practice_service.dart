import '../services/gutenberg_service.dart';
import 'package:flutter/foundation.dart';

class PracticeService extends ChangeNotifier {
  final GutenbergService _gutenbergService = GutenbergService();
  int _totalExercises = 0;

  // Shared method to fetch random sentences
  Future<Map<String, dynamic>> fetchRandomContent(String selectedSource) async {
    Map<String, dynamic> result = {
      'content': '',
      'bookTitle': '',
      'bookAuthor': '',
      'currentBookId': '',
    };

    if (selectedSource == 'AI') {
      // Fetch content from AI
      result['content'] = "This is a random sentence from AI.";
      result['bookTitle'] = "AI Generated";
      result['bookAuthor'] = "AI";
      result['currentBookId'] = ""; // No book ID for AI
    } else {
      // Fetch content from Books using GutenbergService
      try {
        var apiResult = await _gutenbergService.fetchRandomSentence();

        // Clean the sentence by replacing all whitespace sequences with a single space
        result['content'] = (apiResult['sentence'] ?? "No sentence found")
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        result['bookTitle'] = apiResult['title'] ?? "Unknown Title";
        result['bookAuthor'] = apiResult['author'] ?? "Unknown Author";
        result['currentBookId'] = apiResult['bookId'] ?? "";
      } catch (e) {
        result['content'] = "Error fetching sentence: $e";
        result['bookTitle'] = "";
        result['bookAuthor'] = "";
        result['currentBookId'] = "";
      }
    }

    return result;
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
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), ''); // Remove punctuation
  }

  // Method to complete an exercise
  void completeExercise({String practiceType = 'general'}) {
    _totalExercises++;
    // Add any additional logic for tracking specific types of exercises
    // For example, you could track reading vs. listening exercises
    notifyListeners(); // Notify listeners about the change
  }

  // Getter for total exercises
  int get totalExercises => _totalExercises;
}
