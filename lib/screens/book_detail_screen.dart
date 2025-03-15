import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';
import '../services/gutenberg_service.dart';

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final GutenbergService _gutenbergService = GutenbergService();
  Book? _book;
  bool _isLoading = true;
  double _fontSize = 16.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBook() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final book = await _gutenbergService.fetchBook(widget.bookId);
      setState(() {
        _book = book;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading book: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(_book?.title ?? 'Book Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            onPressed: () {
              setState(() {
                _fontSize = (_fontSize - 1).clamp(12.0, 24.0);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            onPressed: () {
              setState(() {
                _fontSize = (_fontSize + 1).clamp(12.0, 24.0);
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
              ? const Center(child: Text('Book not available'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _book!.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'By ${_book!.author}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Text(
                            _book!.content,
                            style: TextStyle(
                              fontSize: _fontSize,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
