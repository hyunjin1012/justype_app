import 'package:flutter/material.dart';
import '../services/sentence_manager.dart';
import 'package:go_router/go_router.dart';
import '../services/progress_service.dart';
import 'enhanced_feedback.dart';

class PracticeContent extends StatefulWidget {
  final String title;
  final Widget Function(String sentence) sentenceDisplay;
  final Widget Function(
      TextEditingController controller,
      Function() checkAnswer,
      String feedback,
      bool isCheckButtonEnabled) inputArea;
  final Function() onRefresh;
  final String? heroTag;
  final SentenceManager sentenceManager;
  final ScrollController? scrollController;
  final bool showSourceSelector;

  const PracticeContent({
    super.key,
    required this.title,
    required this.sentenceDisplay,
    required this.inputArea,
    required this.onRefresh,
    this.heroTag,
    required this.sentenceManager,
    this.scrollController,
    this.showSourceSelector = true,
  });

  @override
  State<PracticeContent> createState() => _PracticeContentState();
}

class _PracticeContentState extends State<PracticeContent> {
  final TextEditingController _textController = TextEditingController();
  final ProgressService _progressService = ProgressService();
  String _feedback = "";
  bool _isLoading = false;
  bool _isCheckButtonEnabled = true;

  // Add tracking variables
  int _correctAnswers = 0;
  int _totalAttempts = 0;

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

  void _checkAnswer() async {
    final userInput = _textController.text;
    if (userInput.isEmpty) return;

    final isCorrect = widget.sentenceManager.checkAnswer(userInput);

    // Track progress
    _totalAttempts++;
    if (isCorrect) {
      _correctAnswers++;
      // Save progress based on practice type
      final practiceType =
          widget.title.contains('Reading') ? 'reading' : 'listening';
      _progressService.completeExercise(practiceType: practiceType);

      // Disable check button when answer is correct
      setState(() {
        _isCheckButtonEnabled = false;
        _feedback = "Correct! Great job.";
      });
    } else {
      setState(() {
        _feedback = "Not quite right. Try again or get a new sentence.";
      });
    }
  }

  Future<void> _fetchRandomSentence() async {
    setState(() {
      _isLoading = true;
      _feedback = "";
      _isCheckButtonEnabled =
          true; // Reset button state when fetching new sentence
    });

    await widget.sentenceManager.fetchContent(
      forceRefresh: true,
      onLoadingChanged: (isLoading) {
        setState(() {
          _isLoading = isLoading;
        });
      },
      onContentUpdated: () {
        setState(() {});
      },
    );

    _textController.clear();
  }

  Future<void> _fetchNewSentence() async {
    await _fetchRandomSentence();
  }

  void _navigateToBookDetail(String bookId) {
    if (bookId.isNotEmpty) {
      GoRouter.of(context).push('/book/$bookId');
    }
  }

  Widget _buildSourceSelector(
      String selectedSource, Function(String) onSourceChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Books'),
          selected: selectedSource == 'Books',
          onSelected: (selected) {
            if (selected) onSourceChanged('Books');
          },
        ),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('AI'),
          selected: selectedSource == 'AI',
          onSelected: (selected) {
            if (selected) onSourceChanged('AI');
          },
        ),
      ],
    );
  }

  Widget _buildBookSourceInfo(
    BuildContext context,
    String title,
    String author,
    String bookId,
    Function(String) onTap,
    String selectedSource,
  ) {
    if (selectedSource != 'Books' || title.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => onTap(bookId),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.book),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    author,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _showEnhancedFeedback() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EnhancedFeedback(
                userInput: _textController.text,
                correctSentence: widget.sentenceManager.currentSentence,
                isCorrect:
                    widget.sentenceManager.checkAnswer(_textController.text),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
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
                controller: widget.scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Source selector (optional)
                      if (widget.showSourceSelector)
                        _buildSourceSelector(
                          widget.sentenceManager.selectedSource,
                          (newSource) {
                            widget.sentenceManager.setSource(newSource);
                            _fetchRandomSentence();
                          },
                        ),
                      const SizedBox(height: 32),
                      // Display book source info (optional)
                      if (widget.showSourceSelector)
                        _buildBookSourceInfo(
                          context,
                          widget.sentenceManager.bookTitle,
                          widget.sentenceManager.bookAuthor,
                          widget.sentenceManager.currentBookId,
                          _navigateToBookDetail,
                          widget.sentenceManager.selectedSource,
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
                              widget.sentenceManager.currentSentence),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            // Input area with feedback
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Input area using the provided builder
                  widget.inputArea(
                    _textController,
                    _checkAnswer,
                    "", // Empty feedback since we'll show it separately
                    _isCheckButtonEnabled,
                  ),
                  // Feedback message and button
                  if (_feedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _feedback,
                      style: TextStyle(
                        color: widget.sentenceManager
                                .checkAnswer(_textController.text)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showEnhancedFeedback,
                      icon: const Icon(Icons.feedback),
                      label: const Text('View Detailed Feedback'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _fetchRandomSentence,
        tooltip: 'Next Sentence',
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Next'),
      ),
    );
  }
}
