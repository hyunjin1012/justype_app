import 'dart:math';
import '../services/practice_service.dart';

class SentenceManager {
  final PracticeService _practiceService = PracticeService();
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

      final result = await _practiceService.fetchRandomContent(_selectedSource);

      if (_selectedSource == 'Books') {
        _booksSentence = result['content'];
      } else {
        _aiSentence = result['content'];
      }

      _currentSentence =
          _selectedSource == 'Books' ? _booksSentence : _aiSentence;
      _bookTitle = result['bookTitle'];
      _bookAuthor = result['bookAuthor'];
      _currentBookId = result['currentBookId'];
      _isLoading = false;

      if (onLoadingChanged != null) {
        onLoadingChanged(false);
      }

      if (onContentUpdated != null) {
        onContentUpdated();
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

  // Extract sentences from book content
  List<String> extractSentencesFromText(String content) {
    final rawSentences = content.split(RegExp(r'(?<=[.!?])\s+'));

    // Filter out empty sentences and very short ones
    return rawSentences
        .where((s) => s.trim().length > 20 && s.trim().length < 200)
        .map((s) => s.replaceAll(RegExp(r'\s+'), ' ').trim())
        .toList();
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
