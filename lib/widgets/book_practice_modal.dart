import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/practice_service.dart';
import '../services/combined_tts_service.dart';
import '../widgets/practice_input_area.dart';
import '../widgets/sentence_display_card.dart';
import '../widgets/visibility_toggle.dart';
import '../widgets/practice_mode_selector.dart';
import '../services/book_sentence_manager.dart';
import '../services/progress_service.dart';
import '../services/feedback_service.dart';
import 'enhanced_feedback.dart';

class BookPracticeModal extends StatefulWidget {
  final Book book;
  final ScrollController scrollController;

  const BookPracticeModal({
    super.key,
    required this.book,
    required this.scrollController,
  });

  @override
  State<BookPracticeModal> createState() => _BookPracticeModalState();
}

class _BookPracticeModalState extends State<BookPracticeModal> {
  final TextEditingController _textController = TextEditingController();
  bool _isListeningMode = false;
  final CombinedTtsService _ttsService = CombinedTtsService();
  bool _isTextVisible = true;
  final BookSentenceManager _sentenceManager = BookSentenceManager();
  final PracticeService _practiceService = PracticeService();
  final FeedbackService _feedbackService = FeedbackService();
  String _feedback = "";
  String _currentSentence = "";
  bool _isCheckButtonEnabled = true;
  final ProgressService _progressService = ProgressService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _feedbackService.initialize();
    _initializeBookSentences();
  }

  Future<void> _initializeBookSentences() async {
    setState(() {
      _isLoading = true;
    });

    // Check if audio challenge is available when in listening mode
    if (_isListeningMode &&
        !_progressService.isBooksAudioChallengeAvailableToday()) {
      setState(() {
        _isLoading = false;
        _feedback =
            "You've already completed your daily Books audio challenge. Please try again tomorrow.";
      });
      return;
    }

    await _sentenceManager.initializeWithBook(widget.book);

    setState(() {
      _currentSentence = _sentenceManager.currentSentence;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _ttsService.dispose();
    _feedbackService.dispose();
    super.dispose();
  }

  void _toggleMode() {
    // Check if audio challenge is available when switching to listening mode
    if (!_isListeningMode &&
        !_progressService.isBooksAudioChallengeAvailableToday()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You\'ve already completed your daily Books audio challenge. Please try again tomorrow.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isListeningMode = !_isListeningMode;
      // Reset visibility when switching to listening mode
      if (_isListeningMode) {
        _isTextVisible = false;
      } else {
        _isTextVisible = true;
      }
      _feedback = ""; // Clear feedback when switching modes
    });
  }

  void _toggleTextVisibility() {
    setState(() {
      _isTextVisible = !_isTextVisible;
    });
  }

  void _speakSentence() {
    if (!mounted) return;

    _ttsService.speak(_sentenceManager.currentSentence, onStateChange: () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _checkAnswer() async {
    final userInput = _textController.text;
    if (userInput.isEmpty) return;

    final currentSentence = _sentenceManager.currentSentence;
    print("Checking answer: '$userInput' against '$currentSentence'");

    final isCorrect = _practiceService.checkAnswer(userInput, currentSentence);
    print("Answer is correct: $isCorrect");

    if (isCorrect) {
      // Play correct sound and haptic feedback
      await _feedbackService.playCorrectSound();

      setState(() {
        _feedback = "Correct! Great job.";
        _isCheckButtonEnabled = false; // Disable button if answer is correct
      });

      // Record progress when the answer is correct
      // Determine the practice type based on the current mode
      final practiceType = _isListeningMode ? 'audio' : 'text';
      print("Recording exercise completion: $practiceType");

      // Update progress using the completeExercise method
      await _progressService.completeExercise(practiceType: practiceType);

      // If it was an audio challenge, update the last Books audio challenge date
      if (_isListeningMode) {
        await _progressService.updateLastBooksAudioChallengeDate();
      }

      print(
          "Progress updated. Total exercises: ${_progressService.getTotalExercises()}");
    } else {
      // Play wrong sound and haptic feedback
      await _feedbackService.playWrongSound();

      setState(() {
        _feedback = "Not quite right. Try again or get a new sentence.";
      });
    }

    print("Feedback after check: $_feedback");
  }

  Future<void> _getNextSentence() async {
    // Check if audio challenge is available when in listening mode
    if (_isListeningMode &&
        !_progressService.isBooksAudioChallengeAvailableToday()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'You\'ve already completed your daily Books audio challenge. Please try again tomorrow.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _textController.clear();
      _feedback = "";
    });

    await _sentenceManager.getNextSentence();

    // Play load sound and haptic feedback when content is updated
    await _feedbackService.playLoadSound();

    setState(() {
      _currentSentence = _sentenceManager.currentSentence;
      _isLoading = false;
      _isCheckButtonEnabled = true;
    });
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
                correctSentence: _sentenceManager.currentSentence,
                isCorrect: _practiceService.checkAnswer(
                    _textController.text, _sentenceManager.currentSentence),
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
        title: Text('Type with ${widget.book.title}'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode selector
          PracticeModeSelector(
            isListeningMode: _isListeningMode,
            onSelectionChanged: (Set<bool> selection) {
              _toggleMode();
            },
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Sentence display section
                    if (_isListeningMode)
                      Column(
                        children: [
                          _ttsService.buildSpeakButton(
                              context, _speakSentence, _ttsService.isSpeaking),
                          const SizedBox(height: 16),
                          VisibilityToggle(
                            isVisible: _isTextVisible,
                            onToggle: _toggleTextVisibility,
                          ),
                          if (_isTextVisible)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SentenceDisplayCard(
                                  sentence: _sentenceManager.currentSentence),
                            ),
                        ],
                      )
                    else
                      SentenceDisplayCard(
                        sentence: _sentenceManager.currentSentence,
                        textStyle: Theme.of(context).textTheme.titleLarge,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Input area and feedback - stays at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                PracticeInputArea(
                  controller: _textController,
                  onCheck: _checkAnswer,
                  feedback: "", // Empty feedback since we'll show it separately
                  labelText: 'Type what you see/hear',
                  isCheckButtonEnabled: _isCheckButtonEnabled,
                ),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _feedback,
                    style: TextStyle(
                      color: _practiceService.checkAnswer(_textController.text,
                              _sentenceManager.currentSentence)
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
                const SizedBox(height: 32), // Add spacing at the bottom
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _getNextSentence,
        tooltip: 'Next Sentence',
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Next'),
      ),
    );
  }
}
