import 'package:flutter/material.dart';
import '../services/gutenberg_service.dart';

class PracticeService {
  final GutenbergService _gutenbergService = GutenbergService();

  // Shared method to fetch random sentences
  Future<Map<String, dynamic>> fetchRandomContent(
      String selectedSource, bool isLoading) async {
    Map<String, dynamic> result = {
      'isLoading': true,
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
      result['isLoading'] = false;
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
        result['isLoading'] = false;
      } catch (e) {
        result['content'] = "Error fetching sentence: $e";
        result['bookTitle'] = "";
        result['bookAuthor'] = "";
        result['currentBookId'] = "";
        result['isLoading'] = false;
      }
    }

    return result;
  }

  // Shared method to check user input against target text
  bool checkAnswer(String userInput, String targetText) {
    // Normalize both strings by trimming whitespace and comparing case-insensitively
    final normalizedUserInput =
        userInput.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    final normalizedTarget =
        targetText.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    return normalizedUserInput == normalizedTarget;
  }

  // Shared widget for source selection
  Widget buildSourceSelector(
      String selectedSource, Function(String) onSourceChanged) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'Books',
          label: Text('Books'),
          icon: Icon(Icons.menu_book),
        ),
        ButtonSegment<String>(
          value: 'AI',
          label: Text('AI'),
          icon: Icon(Icons.smart_toy),
        ),
      ],
      selected: {selectedSource},
      onSelectionChanged: (Set<String> selection) {
        onSourceChanged(selection.first);
      },
    );
  }

  // Shared widget for book source information
  Widget buildBookSourceInfo(
      BuildContext context,
      String bookTitle,
      String bookAuthor,
      String currentBookId,
      Function() onNavigate,
      String selectedSource) {
    // For AI source, don't show book info
    if (selectedSource == 'AI') {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16.0),
        child: Text(
          'AI Generated Content',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    // For Books source with empty info
    if (bookTitle.isEmpty && bookAuthor.isEmpty) {
      return const SizedBox.shrink();
    }

    // For Books source with info
    return InkWell(
      onTap: currentBookId.isNotEmpty ? onNavigate : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'From: $bookTitle${bookAuthor.isNotEmpty ? ' by $bookAuthor' : ''}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: currentBookId.isNotEmpty
                          ? TextDecoration.underline
                          : null,
                      color: currentBookId.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            if (currentBookId.isNotEmpty) const SizedBox(width: 4),
            if (currentBookId.isNotEmpty)
              const Icon(Icons.open_in_new, size: 16),
          ],
        ),
      ),
    );
  }

  // Shared widget for feedback text
  Widget buildFeedbackText(String feedback) {
    return Text(
      feedback,
      style: TextStyle(
        color: feedback == "Correct!" ? Colors.green : Colors.red,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
