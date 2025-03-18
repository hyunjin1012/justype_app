import '../models/book.dart';
import 'sentence_manager.dart';
import 'gutenberg_service.dart';
import 'dart:math';

class BookSentenceManager extends SentenceManager {
  final GutenbergService _gutenbergService = GutenbergService();
  String _currentSentence = "";
  String _bookId = "";
  String _bookTitle = "";
  String _bookAuthor = "";
  List<String> _sentences = [];
  final Random _random = Random();

  Future<void> initializeWithBook(Book book) async {
    _bookId = book.id;
    _bookTitle = book.title;
    _bookAuthor = book.author;

    // Extract sentences from the book content we already have
    _sentences = extractSentencesFromText(book.content);

    // Get the first sentence
    if (_sentences.isNotEmpty) {
      _currentSentence = _sentences[_random.nextInt(_sentences.length)];
    } else {
      _currentSentence = "No suitable sentences found in this book.";
    }
  }

  @override
  Future<void> fetchContent({
    bool forceRefresh = false,
    Function(bool)? onLoadingChanged,
    Function()? onContentUpdated,
  }) async {
    // This method is now simpler since we already have the sentences
    if (onLoadingChanged != null) {
      onLoadingChanged(true);
    }

    if (_sentences.isEmpty && _bookId.isNotEmpty) {
      // Only fetch from the service if we don't have sentences but have a book ID
      final result =
          await _gutenbergService.getProcessedSentence(bookId: _bookId);
      _currentSentence =
          result['sentence'] ?? "No suitable sentences found in this book.";
    } else if (_sentences.isNotEmpty) {
      // Get a random sentence from our existing list
      _currentSentence = _sentences[_random.nextInt(_sentences.length)];
    } else {
      _currentSentence = "No book selected.";
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

  @override
  String get bookTitle => _bookTitle;

  @override
  String get bookAuthor => _bookAuthor;

  @override
  String get currentBookId => _bookId;

  // Get the next sentence
  Future<void> getNextSentence() async {
    if (_sentences.isNotEmpty) {
      // Simply get another random sentence from our existing list
      _currentSentence = _sentences[_random.nextInt(_sentences.length)];
    } else if (_bookId.isNotEmpty) {
      // Only fetch if we don't have sentences
      await fetchContent(forceRefresh: true);
    } else {
      _currentSentence = "No suitable sentences found in this book.";
    }
  }
}
