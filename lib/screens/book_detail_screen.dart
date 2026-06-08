import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/book.dart';
import '../services/local_library_service.dart';
import '../widgets/app_surface.dart';
import '../widgets/book_practice_modal.dart';

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
  final LocalLibraryService _libraryService = LocalLibraryService();
  Book? _book;
  bool _isLoading = true;
  String? _errorMessage;
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
      _errorMessage = null;
    });

    try {
      final book = await _libraryService.fetchBook(widget.bookId);
      setState(() {
        _book = book;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading library item: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadBook,
            ),
          ),
        );
      }
    }
  }

  void _showPracticeModal(BuildContext context) {
    if (_book == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => BookPracticeModal(
          book: _book!,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go('/books');
            }
          },
        ),
        title: Text(_book?.title ?? 'Library Item'),
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading library item...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBook,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _book == null
                  ? const Center(child: Text('Library item not available'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _book!.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'By ${_book!.author}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _showPracticeModal(context),
                                  icon: const Icon(Icons.keyboard),
                                  label: const Text('Start Typing'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: _buildContentView(context, _book!),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildContentView(BuildContext context, Book book) {
    switch (book.displayStyle) {
      case 'messages':
        return _buildMessageThread(context, book);
      case 'dialogue':
        return _buildDialogue(context, book);
      case 'lines':
      case 'verse':
        return _buildLinePack(context, book);
      default:
        return AppSurface(
          child: Text(
            _formatProse(book.content),
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.5,
            ),
          ),
        );
    }
  }

  Widget _buildMessageThread(BuildContext context, Book book) {
    final lines = _contentLines(book.content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < lines.length; index++)
          _buildMessageBubble(context, lines[index], index),
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context, String line, int index) {
    final parts = _splitSpeakerLine(line);
    final isOutgoing = index.isOdd;
    final theme = Theme.of(context);

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.72,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOutgoing
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parts.speaker.isNotEmpty)
              Text(
                parts.speaker,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isOutgoing
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (parts.speaker.isNotEmpty) const SizedBox(height: 4),
            Text(
              parts.text,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.35,
                color: isOutgoing
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogue(BuildContext context, Book book) {
    final lines = _contentLines(book.content);
    final theme = Theme.of(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines) ...[
            _buildDialogueLine(context, line),
            if (line != lines.last)
              Divider(
                height: 20,
                color: theme.dividerTheme.color,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDialogueLine(BuildContext context, String line) {
    final parts = _splitSpeakerLine(line);
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (parts.speaker.isNotEmpty)
          SizedBox(
            width: 86,
            child: Text(
              parts.speaker,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Expanded(
          child: Text(
            parts.text,
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinePack(BuildContext context, Book book) {
    final lines = _contentLines(book.content);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.dividerTheme.color ??
                    theme.colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              line,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.4,
                fontStyle:
                    book.displayStyle == 'verse' ? FontStyle.italic : null,
              ),
            ),
          ),
      ],
    );
  }

  List<String> _contentLines(String content) {
    return content
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  _SpeakerLine _splitSpeakerLine(String line) {
    final separator = line.indexOf(':');

    if (separator <= 0) {
      return _SpeakerLine('', line);
    }

    return _SpeakerLine(
      line.substring(0, separator).trim(),
      line.substring(separator + 1).trim(),
    );
  }

  String _formatProse(String content) {
    return content.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _SpeakerLine {
  final String speaker;
  final String text;

  const _SpeakerLine(this.speaker, this.text);
}
