import 'package:flutter/material.dart';
import '../services/sentence_manager.dart';
import '../services/feedback_service.dart';
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
    if (userInput.isEmpty) return;

    final isCorrect = widget.sentenceManager.checkAnswer(userInput);

    if (isCorrect) {
      // Save progress based on practice type
      final practiceType = widget.title.contains('Text') ? 'text' : 'audio';
      // Check if it's an AI challenge by looking at the source
      final isAiChallenge = widget.sentenceManager.selectedSource == 'AI';
      _progressService.completeExercise(
          practiceType: practiceType, isAiChallenge: isAiChallenge);

      // Play correct sound and haptic feedback
      await _feedbackService.playCorrectSound();

      // Disable check button when answer is correct
      if (mounted) {
        setState(() {
          _isCheckButtonEnabled = false;
          _feedback = "Correct! Great job.";
        });
      }
    } else if (mounted) {
      // Play wrong sound and haptic feedback
      await _feedbackService.playWrongSound();

      setState(() {
        _feedback = "Not quite right. Try again or get a new sentence.";
      });
    }
  }

  Future<void> _fetchRandomSentence() async {
    // Check if AI challenge is available when AI source is selected
    if (widget.sentenceManager.selectedSource == 'AI') {
      bool isAiAvailable = true;
      if (widget.title.contains('Text')) {
        isAiAvailable = _progressService.isTextAiChallengeAvailableToday();
      } else if (widget.title.contains('Audio')) {
        isAiAvailable = _progressService.isAudioAiChallengeAvailableToday();
      }

      if (!isAiAvailable) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _feedback =
                "You've already completed your daily AI challenge. Please try again tomorrow or switch to Books mode.";
          });
        }
        return;
      }
    }

    // Check if Books audio challenge is available when in audio mode with Books source
    if (widget.title.contains('Audio') &&
        widget.sentenceManager.selectedSource == 'Books' &&
        !_progressService.isBooksAudioChallengeAvailableToday()) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _feedback =
              "You've already completed your daily Books audio challenge. Please try again tomorrow or switch to AI mode.";
        });
      }
      return;
    }

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

  void _navigateToBookDetail(String bookId) {
    if (bookId.isNotEmpty) {
      GoRouter.of(context).push('/book/$bookId');
    }
  }

  Widget _buildSourceSelector(
      String selectedSource, Function(String) onSourceChanged) {
    // Check if AI is available based on challenge type
    final bool isAiAvailable = widget.title.contains('Text')
        ? _progressService.isTextAiChallengeAvailableToday()
        : _progressService.isAudioAiChallengeAvailableToday();
    // Check if Books audio is available
    final bool isBooksAudioAvailable =
        _progressService.isBooksAudioChallengeAvailableToday();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('Books'),
          selected: selectedSource == 'Books',
          onSelected: (selected) {
            if (selected) {
              // Check if Books audio challenge is available when in audio mode
              if (widget.title.contains('Audio') && !isBooksAudioAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'You\'ve already completed your daily Books audio challenge. Please try again tomorrow.'),
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              onSourceChanged('Books');
            }
          },
          // Disable the chip if Books audio is not available in audio mode
          disabledColor:
              widget.title.contains('Audio') && !isBooksAudioAvailable
                  ? Colors.grey.shade300
                  : null,
        ),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text('AI'),
          selected: selectedSource == 'AI',
          onSelected: (selected) {
            if (selected && isAiAvailable) {
              onSourceChanged('AI');
            } else if (selected && !isAiAvailable) {
              // Show message when trying to select AI when not available
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'You\'ve already completed your daily ${widget.title.contains('Text') ? 'text' : 'audio'} AI challenge. Please try again tomorrow.',
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          // Disable the chip if AI is not available
          disabledColor: !isAiAvailable ? Colors.grey.shade300 : null,
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
                                    if (widget.sentenceManager.selectedSource ==
                                        'Books') ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'This may take a few seconds...',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
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
        onPressed: _isLoading ? null : _fetchRandomSentence,
        tooltip: 'Next Sentence',
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Next'),
      ),
    );
  }
}
