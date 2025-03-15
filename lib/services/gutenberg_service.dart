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
      final data = json.decode(response.body);
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

      metadataData = json.decode(metadataResponse.body);
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

      String content = contentResponse.body;

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

  Future<List<BookItem>> searchBooks(String query, {int page = 1}) async {
    final response = await http.get(
      Uri.parse('$apiUrl/books?search=$query&page=$page'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final booksResponse = BooksResponse.fromJson(data);
      return booksResponse.results;
    } else {
      throw Exception('Failed to search books: ${response.statusCode}');
    }
  }

  Future<Map<String, String>> fetchRandomSentence() async {
    // Fetch a random book from the Gutenberg API
    final response = await http.get(Uri.parse('$apiUrl/books?search='));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
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
          final content = contentResponse.body;
          final sentence = _extractRandomSentence(content);

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

  String _extractRandomSentence(String content) {
    // Split the content into sentences
    final sentences = content.split(RegExp(r'(?<=[.!?])\s+'));

    // Filter out empty sentences and very short ones
    final validSentences = sentences
        .where((s) =>
            s.trim().length > 20 &&
            !s.contains('*** START OF') &&
            !s.contains('*** END OF'))
        .toList();

    // Return a random sentence
    if (validSentences.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(validSentences.length);
      return validSentences[randomIndex].trim();
    } else {
      return 'No suitable sentence found.';
    }
  }
}
