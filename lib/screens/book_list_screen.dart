import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/booksResponse.dart';
import '../services/gutenberg_service.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final GutenbergService _gutenbergService = GutenbergService();
  BooksResponse? _booksResponse;
  bool _isLoading = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreBooks();
    }
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final booksResponse =
          await _gutenbergService.fetchBooks(page: _currentPage);
      setState(() {
        _booksResponse = booksResponse;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted && context.mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading books: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_booksResponse == null || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final moreBooks = await _gutenbergService.fetchBooks(page: nextPage);

      setState(() {
        _currentPage = nextPage;
        _booksResponse!.results.addAll(moreBooks.results);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more books: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Library'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading && _booksResponse == null
          ? const Center(child: CircularProgressIndicator())
          : _booksResponse == null
              ? const Center(child: Text('No books available'))
              : RefreshIndicator(
                  onRefresh: () async {
                    _currentPage = 1;
                    await _loadBooks();
                  },
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount:
                        _booksResponse!.results.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _booksResponse!.results.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final book = _booksResponse!.results[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate to book detail screen
                          context.push('/book/${book.id}');
                        },
                        child: Card(
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: book.formats.imagejpeg != null
                                    ? Image.network(
                                        book.formats.imagejpeg!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(Icons.book, size: 64),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Icon(Icons.book, size: 64),
                                      ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      book.authors.isNotEmpty
                                          ? book.authors.first.name
                                          : 'Unknown Author',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
