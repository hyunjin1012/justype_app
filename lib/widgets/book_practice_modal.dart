import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/practice_service.dart';
import '../services/combined_tts_service.dart';
import '../widgets/sentence_display_card.dart';
import '../widgets/visibility_toggle.dart';
import '../widgets/practice_mode_selector.dart';
import '../services/book_sentence_manager.dart';
import '../services/progress_service.dart';
import '../services/feedback_service.dart';
import 'enhanced_feedback.dart';
import 'practice_session_scaffold.dart';
import 'save_prompt_action.dart';
import '../widgets/speech_input_area.dart';

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
  DateTime? _sessionStartedAt;

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

    await _sentenceManager.initializeWithBook(widget.book);

    if (!mounted) return;

    setState(() {
      _currentSentence = _sentenceManager.currentSentence;
      _sessionStartedAt = DateTime.now();
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
    if (userInput.isEmpty || !_sentenceManager.hasAvailablePrompt) return;

    final currentSentence = _sentenceManager.currentSentence;
    final wordCount = _countWords(currentSentence);
    final elapsedSeconds = _elapsedSeconds();

    final isCorrect = _practiceService.checkAnswer(userInput, currentSentence);

    if (isCorrect) {
      // Play correct sound and haptic feedback
      await _feedbackService.playCorrectSound();

      if (mounted) {
        setState(() {
          _feedback = _buildCompletionMessage(currentSentence);
          _isCheckButtonEnabled = false; // Disable button if answer is correct
        });
      }

      // Record progress when the answer is correct
      // Determine the practice type based on the current mode
      final practiceType = _isListeningMode ? 'audio' : 'text';

      // Update progress using the completeExercise method
      await _progressService.completeExercise(
        practiceType: practiceType,
        prompt: currentSentence,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );
    } else {
      await _progressService.recordAnswerAttempt(
        false,
        practiceType: _isListeningMode ? 'audio' : 'text',
        prompt: currentSentence,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );

      // Play wrong sound and haptic feedback
      await _feedbackService.playWrongSound();

      if (!mounted) return;

      setState(() {
        _feedback = "Not quite right. Try again or get a new sentence.";
      });
    }
  }

  Future<void> _getNextSentence() async {
    setState(() {
      _isLoading = true;
      _textController.clear();
      _feedback = "";
    });

    await _sentenceManager.getNextSentence();

    // Play load sound and haptic feedback when content is updated
    await _feedbackService.playLoadSound();

    if (!mounted) return;

    setState(() {
      _currentSentence = _sentenceManager.currentSentence;
      _sessionStartedAt = DateTime.now();
      _isLoading = false;
      _isCheckButtonEnabled = true;
    });
  }

  String _buildCompletionMessage(String sentence) {
    final startedAt = _sessionStartedAt;
    if (startedAt == null) {
      return "Correct! Great job.";
    }

    final elapsedSeconds = _elapsedSeconds();
    final wordCount = _countWords(sentence);

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
    return PracticeSessionScaffold(
      title: 'Type with ${widget.book.title}',
      automaticallyImplyLeading: false,
      scrollController: widget.scrollController,
      actions: [
        SavePromptAction(
          prompt: _isLoading ? '' : _currentSentence,
          sourceLabel: 'Library: ${widget.book.title}',
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          PracticeModeSelector(
            isListeningMode: _isListeningMode,
            onSelectionChanged: (Set<bool> selection) {
              _toggleMode();
            },
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_isListeningMode)
            Column(
              children: [
                _ttsService.buildSpeakButton(
                  context,
                  _speakSentence,
                  _ttsService.isSpeaking,
                ),
                const SizedBox(height: 16),
                VisibilityToggle(
                  isVisible: _isTextVisible,
                  onToggle: _toggleTextVisibility,
                ),
                if (_isTextVisible)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SentenceDisplayCard(sentence: _currentSentence),
                  ),
              ],
            )
          else
            SentenceDisplayCard(
              sentence: _currentSentence,
              textStyle: Theme.of(context).textTheme.titleLarge,
            ),
        ],
      ),
      inputArea: SpeechInputArea(
        controller: _textController,
        onCheck: _checkAnswer,
        labelText: 'Type or speak what you see/hear',
        isCheckButtonEnabled:
            _isCheckButtonEnabled && _sentenceManager.hasAvailablePrompt,
      ),
      feedback: _feedback,
      isFeedbackCorrect: _feedback.isEmpty
          ? null
          : _practiceService.checkAnswer(
              _textController.text,
              _sentenceManager.currentSentence,
            ),
      onShowDetails: _feedback.isEmpty ? null : _showEnhancedFeedback,
      onNext: _isLoading ? null : _getNextSentence,
      nextLabel: 'New sentence',
    );
  }
}
