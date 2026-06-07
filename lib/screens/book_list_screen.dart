import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/books_response.dart';
import '../services/local_library_service.dart';
import '../widgets/app_surface.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final LocalLibraryService _libraryService = LocalLibraryService();
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
          ? await _libraryService.fetchBooks(page: _currentPage)
          : await _libraryService.searchBooks(_currentSearchQuery,
              page: _currentPage);

      setState(() {
        _booksResponse = booksResponse;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
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
          ? await _libraryService.fetchBooks(page: nextPage)
          : await _libraryService.searchBooks(_currentSearchQuery,
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No more books available.')),
          );
        }
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
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
                decoration: InputDecoration(
                  hintText: 'Search books...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                autofocus: true,
                onSubmitted: (query) {
                  _performSearch(query);
                  setState(() {
                    _isSearching = false;
                  });
                },
              )
            : const Text('Book Collection'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close Search' : 'Search Books',
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
        ],
      ),
      body: _isLoading && _booksResponse == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading local library...'),
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
                            return AppSurface(
                              onTap: () => context.push('/book/${book.id}'),
                              padding: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildBookCover(
                                      context,
                                      book,
                                      index,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          book.authors.isNotEmpty
                                              ? book.authors.first.name
                                              : 'Unknown Author',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

  Widget _buildBookCover(
    BuildContext context,
    BookItem book,
    int index,
  ) {
    final theme = Theme.of(context);
    final coverColor = _coverColor(context, book, index);
    final subject = book.subjects.isEmpty ? 'Practice' : book.subjects.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: coverColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _coverIcon(book),
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            subject.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Color _coverColor(BuildContext context, BookItem book, int index) {
    final theme = Theme.of(context);
    final palette = [
      theme.colorScheme.tertiaryContainer,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.primaryContainer,
      theme.colorScheme.surfaceContainerHighest,
      theme.colorScheme.errorContainer,
    ];

    return palette[(book.id + index) % palette.length];
  }

  IconData _coverIcon(BookItem book) {
    final searchable = [
      book.title,
      ...book.subjects,
    ].join(' ').toLowerCase();

    if (searchable.contains('travel') || searchable.contains('city')) {
      return Icons.train;
    }
    if (searchable.contains('work') || searchable.contains('office')) {
      return Icons.work_outline;
    }
    if (searchable.contains('school') || searchable.contains('study')) {
      return Icons.school_outlined;
    }
    if (searchable.contains('health') || searchable.contains('fitness')) {
      return Icons.favorite_border;
    }
    if (searchable.contains('money') || searchable.contains('shopping')) {
      return Icons.receipt_long;
    }
    if (searchable.contains('conversation') ||
        searchable.contains('messages')) {
      return Icons.chat_bubble_outline;
    }
    if (searchable.contains('mystery')) {
      return Icons.search;
    }

    return Icons.menu_book;
  }
}
