import 'package:flutter/material.dart';
import '../services/sentence_manager.dart';
import '../services/feedback_service.dart';
import 'package:go_router/go_router.dart';
import '../services/progress_service.dart';
import 'app_surface.dart';
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
  final List<Widget>? appBarActions;
  final Widget? leading;

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
    this.appBarActions,
    this.leading,
  });

  @override
  State<PracticeContent> createState() => _PracticeContentState();
}

class _PracticeContentState extends State<PracticeContent> {
  final TextEditingController _textController = TextEditingController();
  final ProgressService _progressService = ProgressService();
  final FeedbackService _feedbackService = FeedbackService();
  String _feedback = "";
  bool _isLoading = false;
  bool _isCheckButtonEnabled = true;
  String _loadingMessage = "";
  String _currentBookTitle = "";
  String _currentBookAuthor = "";
  String _currentBookId = "";
  DateTime? _sessionStartedAt;

  @override
  void initState() {
    super.initState();
    // Initialize feedback service
    _feedbackService.initialize();
    // Fetch a random sentence when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRandomSentence();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _feedbackService.dispose();
    super.dispose();
  }

  void _checkAnswer() async {
    final userInput = _textController.text;
    if (userInput.isEmpty || !widget.sentenceManager.hasAvailablePrompt) {
      return;
    }

    final isCorrect = widget.sentenceManager.checkAnswer(userInput);
    final currentSentence = widget.sentenceManager.currentSentence;
    final wordCount = _countWords(currentSentence);
    final elapsedSeconds = _elapsedSeconds();

    if (isCorrect) {
      // Save progress based on practice type
      final practiceType = widget.title.contains('Text') ? 'text' : 'audio';
      await _progressService.completeExercise(
        practiceType: practiceType,
        prompt: currentSentence,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );

      // Play correct sound and haptic feedback
      await _feedbackService.playCorrectSound();

      // Disable check button when answer is correct
      if (mounted) {
        setState(() {
          _isCheckButtonEnabled = false;
          _feedback = _buildCompletionMessage();
        });
      }
    } else {
      await _progressService.recordAnswerAttempt(
        false,
        practiceType: widget.title.contains('Text') ? 'text' : 'audio',
        prompt: currentSentence,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );

      if (!mounted) return;

      // Play wrong sound and haptic feedback
      await _feedbackService.playWrongSound();

      setState(() {
        _feedback = "Not quite right. Try again or get a new sentence.";
      });
    }
  }

  Future<void> _fetchRandomSentence() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _feedback = "";
        _isCheckButtonEnabled =
            true; // Reset button state when fetching new sentence
        _loadingMessage =
            "Loading ${widget.sentenceManager.selectedSource} content...";
        // Clear current book information
        _currentBookTitle = "";
        _currentBookAuthor = "";
        _currentBookId = "";
        _sessionStartedAt = DateTime.now();
      });
    }

    // Clear the controller before any async operations
    if (mounted) {
      _textController.clear();
    }

    await widget.sentenceManager.fetchContent(
      forceRefresh: true,
      onLoadingChanged: (isLoading) {
        if (mounted) {
          setState(() {
            _isLoading = isLoading;
            if (isLoading) {
              _loadingMessage =
                  "Loading ${widget.sentenceManager.selectedSource} content...";
              // Clear current book information
              _currentBookTitle = "";
              _currentBookAuthor = "";
              _currentBookId = "";
              _sessionStartedAt = DateTime.now();
            }
          });
        }
      },
      onContentUpdated: () async {
        if (mounted) {
          // Play load sound and haptic feedback when content is updated
          await _feedbackService.playLoadSound();

          setState(() {
            _loadingMessage = "";
            // Update current book information
            _currentBookTitle = widget.sentenceManager.bookTitle;
            _currentBookAuthor = widget.sentenceManager.bookAuthor;
            _currentBookId = widget.sentenceManager.currentBookId;
          });
        }
      },
    );
  }

  String _buildCompletionMessage() {
    final startedAt = _sessionStartedAt;
    if (startedAt == null) {
      return "Correct! Great job.";
    }

    final elapsedSeconds = _elapsedSeconds();
    final wordCount = _countWords(widget.sentenceManager.currentSentence);

    return "Correct! $wordCount words matched in ${elapsedSeconds}s.";
  }

  int _elapsedSeconds() {
    final startedAt = _sessionStartedAt;
    if (startedAt == null) {
      return 1;
    }

    return DateTime.now().difference(startedAt).inSeconds.clamp(1, 999);
  }

  int _countWords(String sentence) {
    return sentence
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
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
          label: const Text('Library'),
          selected: selectedSource == 'Library',
          onSelected: (selected) {
            if (selected) {
              onSourceChanged('Library');
            }
          },
        ),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('Generated'),
          selected: selectedSource == 'Generated',
          onSelected: (selected) {
            if (selected) {
              onSourceChanged('Generated');
            }
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
    if (selectedSource != 'Library' || title.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AppSurface(
        onTap: () => onTap(bookId),
        padding: const EdgeInsets.all(12.0),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
        leading: widget.leading,
        actions: widget.appBarActions,
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
                          _currentBookTitle,
                          _currentBookAuthor,
                          _currentBookId,
                          _navigateToBookDetail,
                          widget.sentenceManager.selectedSource,
                        ),
                      // Loading indicator or sentence display
                      _isLoading
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    Text(
                                      _loadingMessage,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
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
                    _isCheckButtonEnabled &&
                        widget.sentenceManager.hasAvailablePrompt,
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
        onPressed: _isLoading ? null : _fetchRandomSentence,
        tooltip: 'Next Sentence',
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Next'),
      ),
    );
  }
}
