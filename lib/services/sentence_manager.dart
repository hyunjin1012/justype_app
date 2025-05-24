import 'dart:math';
import 'package:flutter/material.dart';

import '../services/practice_service.dart';
import '../services/gutenberg_service.dart';

class SentenceManager {
  final PracticeService _practiceService = PracticeService();
  final GutenbergService _gutenbergService = GutenbergService();
  String _booksSentence = "";
  String _aiSentence = "This is a random sentence from AI.";
  String _currentSentence = "";
  String _bookTitle = "";
  String _bookAuthor = "";
  String _currentBookId = "";
  String _selectedSource = 'Books';
  bool _isLoading = false;

  // Getters
  String get currentSentence => _currentSentence;
  String get bookTitle => _bookTitle;
  String get bookAuthor => _bookAuthor;
  String get currentBookId => _currentBookId;
  String get selectedSource => _selectedSource;
  bool get isLoading => _isLoading;

  // Set the source
  void setSource(String source) {
    _selectedSource = source;
  }

  // Fetch content with optional force refresh
  Future<void> fetchContent({
    bool forceRefresh = false,
    Function(bool)? onLoadingChanged,
    Function()? onContentUpdated,
  }) async {
    // Only fetch if we need to (force refresh or empty content)
    if (forceRefresh ||
        (_selectedSource == 'Books' && _booksSentence.isEmpty) ||
        (_selectedSource == 'AI' && _aiSentence.isEmpty)) {
      _isLoading = true;
      if (onLoadingChanged != null) {
        onLoadingChanged(true);
      }

      try {
        if (_selectedSource == 'Books') {
          // Use the shared method from GutenbergService
          final result = await _gutenbergService.getProcessedSentence();
          _booksSentence = result['sentence'] ?? "";
          _bookTitle = result['title'] ?? "";
          _bookAuthor = result['author'] ?? "";
          _currentBookId = result['bookId'] ?? "";
        } else {
          // For AI, use the dedicated AI content method
          final result = await _practiceService.fetchAIContent();
          _aiSentence = result['content'];
          _bookTitle = result['bookTitle'];
          _bookAuthor = result['bookAuthor'];
          _currentBookId = result['currentBookId'];
        }

        _currentSentence =
            _selectedSource == 'Books' ? _booksSentence : _aiSentence;
      } catch (e) {
        debugPrint('Error fetching content: $e');
        // Set fallback content
        if (_selectedSource == 'AI') {
          _aiSentence = "The quick brown fox jumps over the lazy dog.";
          _bookTitle = "AI Generated";
          _bookAuthor = "AI";
          _currentBookId = "";
          _currentSentence = _aiSentence;
        }
      } finally {
        _isLoading = false;
        if (onLoadingChanged != null) {
          onLoadingChanged(false);
        }
        if (onContentUpdated != null) {
          onContentUpdated();
        }
      }
    } else {
      // Just switch to the existing content
      _currentSentence =
          _selectedSource == 'Books' ? _booksSentence : _aiSentence;

      if (onContentUpdated != null) {
        onContentUpdated();
      }
    }
  }

  // Extract sentences from book content - keep this for compatibility
  List<String> extractSentencesFromText(String content) {
    // First, preprocess the content to handle abbreviations
    // This ensures we don't split sentences at abbreviations like "Mr."
    String preprocessed = content;

    // Handle common abbreviations
    final abbreviations = [
      'Mr.',
      'Mrs.',
      'Ms.',
      'Dr.',
      'Prof.',
      'St.',
      'Jr.',
      'Sr.'
    ];
    for (var abbr in abbreviations) {
      preprocessed = preprocessed.replaceAllMapped(
        RegExp('$abbr (\\w)'),
        (match) =>
            '${abbr.substring(0, abbr.length - 1)}###PERIOD### ${match.group(1)}',
      );
    }

    // Handle single-letter abbreviations (like initials)
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'([A-Z])\. ([A-Z])'),
      (match) => '${match.group(1)}###PERIOD### ${match.group(2)}',
    );

    // Handle periods inside quotation marks
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'\.("|\")(\s)'),
      (match) => '###PERIOD###${match[1]}${match[2]}',
    );

    // Split by sentence endings (period, exclamation mark, or question mark followed by space)
    final rawSentences = preprocessed.split(RegExp(r'(?<=[.!?])\s+'));

    // Process each sentence
    final processedSentences = rawSentences.map((sentence) {
      // Restore periods in abbreviations
      String processed = sentence.replaceAll('###PERIOD###', '.');
      // Normalize whitespace
      processed = processed.replaceAll(RegExp(r'\s+'), ' ').trim();
      return processed;
    }).toList();

    // Filter out unsuitable sentences
    return processedSentences.where((sentence) {
      // Check length (not too short, not too long)
      if (sentence.trim().length < 20 || sentence.trim().length > 200) {
        return false;
      }

      // Check for unwanted characters or patterns
      if (sentence.contains('(') ||
          sentence.contains(')') ||
          sentence.contains('[') ||
          sentence.contains(']') ||
          sentence.contains('{') ||
          sentence.contains('}') ||
          sentence.contains('_') ||
          sentence.contains('...') ||
          sentence.contains('--')) {
        return false;
      }

      // Ensure the sentence has proper ending punctuation
      if (!sentence.trim().endsWith('.') &&
          !sentence.trim().endsWith('!') &&
          !sentence.trim().endsWith('?')) {
        return false;
      }

      return true;
    }).toList();
  }

  // Get a random sentence from a list
  String getRandomSentenceFromList(List<String> sentences) {
    if (sentences.isEmpty) {
      return "No suitable sentences found.";
    }

    final random = Random();
    return sentences[random.nextInt(sentences.length)];
  }

  // Check if the answer is correct
  bool checkAnswer(String userInput) {
    return _practiceService.checkAnswer(userInput, _currentSentence);
  }
}
