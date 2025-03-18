import 'package:http/http.dart' as http;
import '../models/booksResponse.dart';
import '../models/book.dart';
import 'dart:convert';
import 'dart:math';

class GutenbergService {
  static const String baseUrl = 'https://gutenberg.org';
  static const String apiUrl = 'https://gutendex.com';

  Future<BooksResponse> fetchBooks({int page = 1, int limit = 32}) async {
    final response = await http.get(
      Uri.parse('$apiUrl/books?page=$page&limit=$limit'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return BooksResponse.fromJson(data);
    } else {
      throw Exception('Failed to load books: ${response.statusCode}');
    }
  }

  Future<Book> fetchBook(String bookId) async {
    Map<String, dynamic>? metadataData;
    try {
      // First try to get the book metadata
      final metadataResponse = await http.get(
        Uri.parse('$apiUrl/books?ids=$bookId'),
      );

      if (metadataResponse.statusCode != 200) {
        throw Exception(
            'Failed to load book metadata: ${metadataResponse.statusCode}');
      }

      metadataData = json.decode(utf8.decode(metadataResponse.bodyBytes));
      final results = metadataData?['results'] as List;

      if (results.isEmpty) {
        throw Exception('Book not found');
      }

      final bookData = results.first;
      final title = bookData['title'];
      final authors = (bookData['authors'] as List)
          .map((author) => Author.fromJson(author))
          .toList();
      final authorName =
          authors.isNotEmpty ? authors.first.name : 'Unknown Author';

      // Get the text content URL
      String? textUrl = bookData['formats']['text/plain; charset=utf-8'];
      textUrl ??= bookData['formats']['text/plain'];

      if (textUrl == null) {
        throw Exception('No text format available for this book');
      }

      // Fetch the actual text content
      final contentResponse = await http.get(Uri.parse(textUrl));

      if (contentResponse.statusCode != 200) {
        throw Exception(
            'Failed to load book content: ${contentResponse.statusCode}');
      }

      String content = utf8.decode(contentResponse.bodyBytes);

      // Clean up the content (optional)
      content = _cleanupContent(content);

      return Book(
        id: bookId,
        title: title,
        author: authorName,
        content: content,
      );
    } catch (e) {
      // If the API approach fails, try the direct file approach
      String? title;
      String? author;

      try {
        // Try to extract title and author from the error response if possible
        if (e is Exception && metadataData != null) {
          final results = metadataData['results'] as List;
          if (results.isNotEmpty) {
            final bookData = results.first;
            title = bookData['title'];
            final authors = (bookData['authors'] as List)
                .map((author) => Author.fromJson(author))
                .toList();
            author = authors.isNotEmpty ? authors.first.name : null;
          }
        }
      } catch (_) {
        // Ignore any errors in extracting metadata
      }

      return _fetchBookDirect(bookId, title: title, author: author);
    }
  }

  Future<Book> _fetchBookDirect(String bookId,
      {String? title, String? author}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/files/$bookId/$bookId-0.txt'),
    );

    if (response.statusCode == 200) {
      final content = response.body;

      // Use provided title and author if available, otherwise parse from content
      String bookTitle = title ?? 'Unknown Title';
      String bookAuthor = author ?? 'Unknown Author';

      // Only parse title and author from content if they weren't provided
      if (title == null || author == null) {
        final lines = content.split('\n');

        // Look for title and author in the first 100 lines
        for (int i = 0; i < lines.length && i < 100; i++) {
          final line = lines[i];
          if (title == null && line.contains('Title:')) {
            bookTitle = line.replaceAll('Title:', '').trim();
          }
          if (author == null && line.contains('Author:')) {
            bookAuthor = line.replaceAll('Author:', '').trim();
          }
        }
      }

      return Book(
        id: bookId,
        title: bookTitle,
        author: bookAuthor,
        content: _cleanupContent(content),
      );
    } else {
      throw Exception('Failed to load book: ${response.statusCode}');
    }
  }

  String _cleanupContent(String content) {
    // Remove Project Gutenberg header (typically first 500 lines)
    final lines = content.split('\n');
    int startIndex = 0;

    // Look for the start of the actual content
    for (int i = 0; i < lines.length && i < 500; i++) {
      if (lines[i].contains('*** START OF') ||
          lines[i].contains('*** BEGIN OF')) {
        startIndex = i + 1;
        break;
      }
    }

    // Look for the end of the content
    int endIndex = lines.length;
    for (int i = lines.length - 1; i >= 0 && i >= lines.length - 200; i--) {
      if (lines[i].contains('*** END OF') || lines[i].contains('*** THE END')) {
        endIndex = i;
        break;
      }
    }

    // Extract the actual content
    final contentLines = lines.sublist(startIndex, endIndex);
    return contentLines.join('\n');
  }

  Future<BooksResponse> searchBooks(String query, {int page = 1}) async {
    final url = '$apiUrl/books?search=$query&page=$page';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return BooksResponse.fromJson(data);
    } else if (response.statusCode == 404) {
      // Return an empty response instead of throwing an exception
      return BooksResponse(count: 0, next: null, previous: null, results: []);
    } else {
      throw Exception('Failed to search books: ${response.statusCode}');
    }
  }

  Future<Map<String, String>> fetchRandomSentence() async {
    // Fetch a random book from the Gutenberg API
    final response = await http.get(Uri.parse('$apiUrl/books?search='));

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final results = data['results'] as List;

      if (results.isNotEmpty) {
        // Get a random book from the results
        final random = Random();
        final randomIndex = random.nextInt(results.length);
        final randomBook = results[randomIndex];
        final bookId = randomBook['id'].toString();
        final bookTitle = randomBook['title'] ?? "Unknown Title";

        // Get author name
        String bookAuthor = "Unknown Author";
        if (randomBook['authors'] != null &&
            (randomBook['authors'] as List).isNotEmpty) {
          bookAuthor = randomBook['authors'][0]['name'] ?? "Unknown Author";
        }

        // Fetch the book content
        final contentResponse =
            await http.get(Uri.parse('$baseUrl/files/$bookId/$bookId-0.txt'));

        if (contentResponse.statusCode == 200) {
          final content = utf8.decode(contentResponse.bodyBytes);

          // Use the improved _extractSentences method instead of _extractRandomSentence
          final sentences = _extractSentences(content);
          String sentence = "No suitable sentence found.";

          if (sentences.isNotEmpty) {
            final randomSentenceIndex = random.nextInt(sentences.length);
            sentence = sentences[randomSentenceIndex];
          }

          return {
            'sentence': sentence,
            'title': bookTitle,
            'author': bookAuthor,
            'bookId': bookId
          };
        } else {
          throw Exception(
              'Failed to load book content: ${contentResponse.statusCode}');
        }
      } else {
        throw Exception('No books found.');
      }
    } else {
      throw Exception('Failed to load random book: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getProcessedSentence({String? bookId}) async {
    Map<String, dynamic> result = {
      'sentence': '',
      'title': '',
      'author': '',
      'bookId': '',
    };

    try {
      if (bookId != null) {
        // Get sentence from a specific book
        final book = await fetchBook(bookId);
        final sentences = _extractSentences(book.content);

        if (sentences.isNotEmpty) {
          final random = Random();
          result['sentence'] = sentences[random.nextInt(sentences.length)];
          result['title'] = book.title;
          result['author'] = book.author;
          result['bookId'] = bookId;
        }
      } else {
        // Get a random sentence from a random book
        result = await fetchRandomSentence();
      }

      return result;
    } catch (e) {
      return result;
    }
  }

  List<String> _extractSentences(String content) {
    // Preprocess content to handle abbreviations
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

    // Handle single-letter abbreviations
    preprocessed = preprocessed.replaceAllMapped(
      RegExp(r'([A-Z])\. ([A-Z])'),
      (match) => '${match.group(1)}###PERIOD### ${match.group(2)}',
    );

    // Split by sentence endings
    final rawSentences = preprocessed.split(RegExp(r'(?<=[.!?])\s+'));

    // Process and filter sentences
    return rawSentences
        .map((s) => s
            .replaceAll('###PERIOD###', '.')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim())
        .where((s) {
      // More thorough filtering
      if (s.length < 20 || s.length > 200) return false;

      // Check for any brackets, parentheses, or other unwanted characters
      if (s.contains('(') ||
          s.contains(')') ||
          s.contains('[') ||
          s.contains(']') ||
          s.contains('{') ||
          s.contains('}') ||
          s.contains('<') ||
          s.contains('>') ||
          s.contains('*') ||
          s.contains('_') ||
          s.contains('...') ||
          s.contains('--') ||
          s.contains('©') ||
          s.contains('®') ||
          s.contains('™') ||
          s.contains('§')) {
        return false;
      }

      // Filter out sentences with Roman numerals
      // This regex matches common Roman numeral patterns
      if (RegExp(r'\b[IVXLCDM]+\b').hasMatch(s)) {
        return false;
      }

      // Ensure proper ending punctuation
      if (!s.endsWith('.') && !s.endsWith('!') && !s.endsWith('?')) {
        return false;
      }

      // Check for chapter headings or all-caps text
      if (s.toUpperCase() == s && s.length > 10) {
        return false;
      }

      return true;
    }).toList();
  }
}
