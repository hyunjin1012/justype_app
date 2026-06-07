import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/book.dart';
import '../models/books_response.dart';
import 'progress_service.dart';

class LocalLibraryService {
  static const List<String> _assetPaths = [
    'assets/corpus/books.json',
    'assets/corpus/original_packs.json',
  ];

  final Random _random = Random();
  List<_LocalBookRecord>? _catalog;

  Future<BooksResponse> fetchBooks({int page = 1, int limit = 32}) async {
    final books = await _loadCatalog();
    return _buildResponse(books, page: page, limit: limit);
  }

  Future<BooksResponse> searchBooks(String query, {int page = 1}) async {
    final books = await _loadCatalog();
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return _buildResponse(books, page: page);
    }

    final results = books.where((book) {
      final searchable = [
        book.title,
        book.author,
        ...book.subjects,
      ].join(' ').toLowerCase();

      return searchable.contains(normalizedQuery);
    }).toList();

    return _buildResponse(results, page: page);
  }

  Future<Book> fetchBook(String bookId) async {
    final books = await _loadCatalog();
    final book =
        books.where((entry) => entry.id.toString() == bookId).firstOrNull;

    if (book == null) {
      throw Exception('Book not found in the local library.');
    }

    return Book(
      id: book.id.toString(),
      title: book.title,
      author: book.author,
      content: book.content,
      subjects: book.subjects,
      displayStyle: book.displayStyle,
    );
  }

  Future<Map<String, String>> fetchRandomSentence() async {
    final books = await _loadCatalog();
    final candidates = books
        .expand((book) => _extractSentences(book.content).map(
              (sentence) => _LocalSentenceCandidate(
                sentence: sentence,
                title: book.title,
                author: book.author,
                bookId: book.id.toString(),
              ),
            ))
        .toList();

    final candidate = await _pickUnpracticedCandidate(candidates);

    return {
      'sentence': candidate?.sentence ??
          'You have practiced every local library prompt. Try Generated for a fresh sentence.',
      'title': candidate?.title ?? 'Library Complete',
      'author': candidate?.author ?? 'JusType',
      'bookId': candidate?.bookId ?? '',
    };
  }

  Future<Map<String, dynamic>> getProcessedSentence({String? bookId}) async {
    try {
      if (bookId != null) {
        final book = await fetchBook(bookId);
        final candidates = _extractSentences(book.content)
            .map(
              (sentence) => _LocalSentenceCandidate(
                sentence: sentence,
                title: book.title,
                author: book.author,
                bookId: book.id,
              ),
            )
            .toList();
        final candidate = await _pickUnpracticedCandidate(candidates);

        return {
          'sentence': candidate?.sentence ??
              'You have practiced every prompt in this book.',
          'title': book.title,
          'author': book.author,
          'bookId': book.id,
        };
      }

      return await fetchRandomSentence();
    } catch (_) {
      return {
        'sentence': 'Reliable practice starts with one accurate sentence.',
        'title': 'Generated Practice',
        'author': 'JusType Library',
        'bookId': '',
      };
    }
  }

  Future<List<_LocalBookRecord>> _loadCatalog() async {
    if (_catalog != null) {
      return _catalog!;
    }

    final records = <_LocalBookRecord>[];

    for (final assetPath in _assetPaths) {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = json.decode(raw) as List<dynamic>;
      records.addAll(decoded.map((entry) {
        final data = entry as Map<String, dynamic>;
        return _LocalBookRecord(
          id: data['id'] as int,
          title: data['title'] as String,
          author: data['author'] as String,
          subjects: List<String>.from(data['subjects'] as List<dynamic>),
          content: data['content'] as String,
          displayStyle: data['displayStyle'] as String? ?? 'prose',
        );
      }));
    }

    _catalog = records;

    return _catalog!;
  }

  BooksResponse _buildResponse(
    List<_LocalBookRecord> books, {
    int page = 1,
    int limit = 32,
  }) {
    final safePage = page < 1 ? 1 : page;
    final start = (safePage - 1) * limit;

    if (start >= books.length) {
      return BooksResponse(
        count: books.length,
        next: null,
        previous: safePage > 1 ? 'local://books?page=${safePage - 1}' : null,
        results: [],
      );
    }

    final end = min(start + limit, books.length);
    final pageBooks = books.sublist(start, end);

    return BooksResponse(
      count: books.length,
      next: end < books.length ? 'local://books?page=${safePage + 1}' : null,
      previous: safePage > 1 ? 'local://books?page=${safePage - 1}' : null,
      results: pageBooks.map(_toBookItem).toList(),
    );
  }

  BookItem _toBookItem(_LocalBookRecord book) {
    return BookItem(
      id: book.id,
      title: book.title,
      authors: [
        Author(name: book.author),
      ],
      subjects: book.subjects,
      bookshelves: const ['JusType Local Library'],
      languages: const ['en'],
      copyright: false,
      mediaType: 'Text',
      formats: Formats(),
      downloadCount: 0,
    );
  }

  List<String> _extractSentences(String content) {
    var preprocessed = content;
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

    for (final abbreviation in abbreviations) {
      preprocessed = preprocessed.replaceAllMapped(
        RegExp('$abbreviation (\\w)'),
        (match) =>
            '${abbreviation.substring(0, abbreviation.length - 1)}###PERIOD### ${match.group(1)}',
      );
    }

    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'([A-Z])\. ([A-Z])'),
      (match) => '${match.group(1)}###PERIOD### ${match.group(2)}',
    );

    return preprocessed
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((sentence) => sentence
            .replaceAll('###PERIOD###', '.')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim()
            .replaceFirst(RegExp(r'^[A-Za-z][A-Za-z ]{0,32}:\s*'), ''))
        .where((sentence) {
      if (sentence.length < 20 || sentence.length > 200) {
        return false;
      }

      if (!sentence.endsWith('.') &&
          !sentence.endsWith('!') &&
          !sentence.endsWith('?')) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<_LocalSentenceCandidate?> _pickUnpracticedCandidate(
    List<_LocalSentenceCandidate> candidates,
  ) async {
    if (candidates.isEmpty) {
      return null;
    }

    final progressService = ProgressService();
    await progressService.loadProgress();

    final unpracticed = candidates
        .where((candidate) => !progressService.hasPracticedPrompt(
              candidate.sentence,
            ))
        .toList();

    if (unpracticed.isEmpty) {
      return null;
    }

    return unpracticed[_random.nextInt(unpracticed.length)];
  }
}

class _LocalBookRecord {
  final int id;
  final String title;
  final String author;
  final List<String> subjects;
  final String content;
  final String displayStyle;

  const _LocalBookRecord({
    required this.id,
    required this.title,
    required this.author,
    required this.subjects,
    required this.content,
    required this.displayStyle,
  });
}

class _LocalSentenceCandidate {
  final String sentence;
  final String title;
  final String author;
  final String bookId;

  const _LocalSentenceCandidate({
    required this.sentence,
    required this.title,
    required this.author,
    required this.bookId,
  });
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }

    return null;
  }
}
