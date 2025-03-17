import 'dart:math';
import '../models/book.dart';
import 'sentence_manager.dart';

class BookSentenceManager extends SentenceManager {
  List<String> _sentences = [];
  String _currentSentence = "";

  void initializeWithBook(Book book) {
    _sentences = extractSentencesFromText(book.content);
    fetchContent(forceRefresh: true);
  }

  @override
  Future<void> fetchContent({
    bool forceRefresh = false,
    Function(bool)? onLoadingChanged,
    Function()? onContentUpdated,
  }) async {
    if (onLoadingChanged != null) {
      onLoadingChanged(true);
    }

    if (_sentences.isEmpty) {
      _currentSentence = "No suitable sentences found in this book.";
    } else {
      _currentSentence = getRandomSentenceFromList(_sentences);
    }

    if (onLoadingChanged != null) {
      onLoadingChanged(false);
    }

    if (onContentUpdated != null) {
      onContentUpdated();
    }
  }

  @override
  String get currentSentence => _currentSentence;

  // New method to get the next sentence
  void getNextSentence() {
    if (_sentences.isNotEmpty) {
      _currentSentence = getRandomSentenceFromList(_sentences);
    } else {
      _currentSentence = "No suitable sentences found in this book.";
    }
  }
}
