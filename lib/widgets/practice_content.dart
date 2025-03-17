import 'package:flutter/material.dart';
import '../services/sentence_manager.dart';
import 'package:go_router/go_router.dart';

class PracticeContent extends StatefulWidget {
  final String title;
  final Widget Function(String sentence) sentenceDisplay;
  final Widget Function(TextEditingController controller,
      Function() checkAnswer, String feedback) inputArea;
  final Function() onRefresh;
  final String heroTag;

  const PracticeContent({
    super.key,
    required this.title,
    required this.sentenceDisplay,
    required this.inputArea,
    required this.onRefresh,
    required this.heroTag,
  });

  @override
  State<PracticeContent> createState() => _PracticeContentState();
}

class _PracticeContentState extends State<PracticeContent> {
  final TextEditingController _textController = TextEditingController();
  final SentenceManager _sentenceManager = SentenceManager();
  String _feedback = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch a random sentence when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRandomSentence();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    bool isCorrect = _sentenceManager.checkAnswer(_textController.text);

    setState(() {
      _feedback = isCorrect ? "Correct!" : "Try again!";
    });
  }

  void _fetchRandomSentence() {
    _sentenceManager.fetchContent(onLoadingChanged: (isLoading) {
      setState(() {
        _isLoading = isLoading;
        if (isLoading) {
          _feedback = "";
          _textController.clear();
        }
      });
    }, onContentUpdated: () {
      setState(() {});
    });
  }

  void _fetchNewSentence() {
    _sentenceManager.fetchContent(
        forceRefresh: true,
        onLoadingChanged: (isLoading) {
          setState(() {
            _isLoading = isLoading;
            if (isLoading) {
              _feedback = "";
              _textController.clear();
            }
          });
        },
        onContentUpdated: () {
          setState(() {});
        });
  }

  void _navigateToBookDetail() {
    if (_sentenceManager.currentBookId.isNotEmpty) {
      GoRouter.of(context).push('/book/${_sentenceManager.currentBookId}');
    }
  }

  Widget _buildSourceSelector(
      String selectedSource, Function(String) onSourceChanged) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'Books',
          label: Text('Books'),
          icon: Icon(Icons.book),
        ),
        ButtonSegment<String>(
          value: 'AI',
          label: Text('AI'),
          icon: Icon(Icons.psychology),
        ),
      ],
      selected: {selectedSource},
      onSelectionChanged: (Set<String> newSelection) {
        onSourceChanged(newSelection.first);
      },
    );
  }

  Widget _buildBookSourceInfo(
      BuildContext context,
      String bookTitle,
      String bookAuthor,
      String currentBookId,
      Function() onNavigate,
      String selectedSource) {
    // For AI source, don't show book info
    if (selectedSource == 'AI') {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16.0),
        child: Text(
          'AI Generated Content',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    // For Books source with empty info
    if (bookTitle.isEmpty && bookAuthor.isEmpty) {
      return const SizedBox.shrink();
    }

    // For Books source with info
    return InkWell(
      onTap: currentBookId.isNotEmpty ? onNavigate : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'From: $bookTitle${bookAuthor.isNotEmpty ? ' by $bookAuthor' : ''}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: currentBookId.isNotEmpty
                          ? TextDecoration.underline
                          : null,
                      color: currentBookId.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            if (currentBookId.isNotEmpty) const SizedBox(width: 4),
            if (currentBookId.isNotEmpty)
              const Icon(Icons.open_in_new, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Source selector
                      _buildSourceSelector(
                        _sentenceManager.selectedSource,
                        (newSource) {
                          _sentenceManager.setSource(newSource);
                          _fetchRandomSentence();
                        },
                      ),
                      const SizedBox(height: 32),
                      // Display book source info
                      _buildBookSourceInfo(
                        context,
                        _sentenceManager.bookTitle,
                        _sentenceManager.bookAuthor,
                        _sentenceManager.currentBookId,
                        _navigateToBookDetail,
                        _sentenceManager.selectedSource,
                      ),
                      // Loading indicator or sentence display
                      _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : widget.sentenceDisplay(
                              _sentenceManager.currentSentence),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            // Input area using the provided builder
            widget.inputArea(_textController, _checkAnswer, _feedback),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading
            ? null
            : () {
                _fetchNewSentence();
                widget.onRefresh();
              },
        tooltip: 'Get New Sentence',
        heroTag: widget.heroTag,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              )
            : const Icon(Icons.refresh),
      ),
    );
  }
}
