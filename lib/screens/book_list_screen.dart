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
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';
  bool _isSearching = false;

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
    _searchController.dispose();
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
      final booksResponse = _currentSearchQuery.isEmpty
          ? await _gutenbergService.fetchBooks(page: _currentPage)
          : await _gutenbergService.searchBooks(_currentSearchQuery,
              page: _currentPage);

      setState(() {
        _booksResponse = booksResponse;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      if (mounted && context.mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to load books. Please try again.')),
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
      final moreBooksResponse = _currentSearchQuery.isEmpty
          ? await _gutenbergService.fetchBooks(page: nextPage)
          : await _gutenbergService.searchBooks(_currentSearchQuery,
              page: nextPage);

      if (moreBooksResponse.results.isNotEmpty) {
        setState(() {
          _currentPage = nextPage;
          _booksResponse!.results.addAll(moreBooksResponse.results);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No more books available.')),
        );
      }
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
      if (e.toString().contains('404')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No more books available.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to load more books. Please try again.')),
        );
      }
    }
  }

  void _performSearch(String query) {
    setState(() {
      _currentSearchQuery = query;
      _currentPage = 1;
      _booksResponse = null;
    });
    _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search books...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
                onSubmitted: (query) {
                  _performSearch(query);
                  setState(() {
                    _isSearching = false;
                  });
                },
              )
            : const Text('Book Collection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  if (_currentSearchQuery.isNotEmpty) {
                    _currentSearchQuery = '';
                    _currentPage = 1;
                    _booksResponse = null;
                    _loadBooks();
                  }
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About'),
                  content: const Text(
                    'This app displays books from Project Gutenberg, a library of over 60,000 free eBooks. '
                    'Project Gutenberg offers free eBooks of classic literature that have expired copyright protection.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading && _booksResponse == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading books... This might take a few seconds.'),
                ],
              ),
            )
          : _booksResponse == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No books available'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadBooks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _currentPage = 1;
                    await _loadBooks();
                  },
                  child: Column(
                    children: [
                      if (_currentSearchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Search results for: "$_currentSearchQuery"',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _currentSearchQuery = '';
                                    _currentPage = 1;
                                    _booksResponse = null;
                                    _searchController.clear();
                                  });
                                  _loadBooks();
                                },
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
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
                          itemCount: _booksResponse!.results.length +
                              (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _booksResponse!.results.length) {
                              return const Center(
                                  child: CircularProgressIndicator());
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
                                                  child: Icon(Icons.book,
                                                      size: 64),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                    ],
                  ),
                ),
    );
  }
}
