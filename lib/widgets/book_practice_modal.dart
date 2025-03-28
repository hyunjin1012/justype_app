import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/practice_service.dart';
import '../services/tts_service.dart';
import '../widgets/practice_input_area.dart';
import '../widgets/sentence_display_card.dart';
import '../widgets/visibility_toggle.dart';
import '../widgets/practice_mode_selector.dart';
import '../services/book_sentence_manager.dart';
import '../services/progress_service.dart';

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
  final TtsService _ttsService = TtsService();
  bool _isTextVisible = true;
  final BookSentenceManager _sentenceManager = BookSentenceManager();
  final PracticeService _practiceService = PracticeService();
  String _feedback = "";
  String _currentSentence = "";
  bool _isCheckButtonEnabled = true;
  final ProgressService _progressService = ProgressService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _initializeBookSentences();
  }

  Future<void> _initializeBookSentences() async {
    setState(() {
      _isLoading = true;
    });

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
    _ttsService.speak(_sentenceManager.currentSentence, onStateChange: () {
      setState(() {});
    });
  }

  void _checkAnswer() async {
    final userInput = _textController.text;
    if (userInput.isEmpty) return;

    final currentSentence = _sentenceManager.currentSentence;
    print("Checking answer: '$userInput' against '$currentSentence'");

    final isCorrect = _practiceService.checkAnswer(userInput, currentSentence);
    print("Answer is correct: $isCorrect");

    setState(() {
      _feedback = isCorrect
          ? "Correct! Great job."
          : "Not quite right. Try again or get a new sentence.";
      _isCheckButtonEnabled = !isCorrect; // Disable button if answer is correct
    });

    // Record progress when the answer is correct
    if (isCorrect) {
      // Determine the practice type based on the current mode
      final practiceType = _isListeningMode ? 'listening' : 'reading';
      print("Recording exercise completion: $practiceType");

      // Update progress using the completeExercise method
      await _progressService.completeExercise(practiceType: practiceType);

      print(
          "Progress updated. Total exercises: ${_progressService.getTotalExercises()}");
    }

    print("Feedback after check: $_feedback");
  }

  Future<void> _getNextSentence() async {
    setState(() {
      _isLoading = true;
      _textController.clear();
      _feedback = "";
    });

    await _sentenceManager.getNextSentence();

    setState(() {
      _currentSentence = _sentenceManager.currentSentence;
      _isLoading = false;
      _isCheckButtonEnabled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice with ${widget.book.title}'),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text(
                  //   _isListeningMode
                  //       ? 'Listening Practice'
                  //       : 'Reading Practice',
                  //   style: Theme.of(context).textTheme.titleLarge,
                  // ),
                  // const SizedBox(height: 24),

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

                  const Spacer(),

                  // Input area
                  PracticeInputArea(
                    controller: _textController,
                    onCheck: _checkAnswer,
                    feedback: _feedback,
                    labelText: 'Type what you see/hear',
                    isCheckButtonEnabled: _isCheckButtonEnabled,
                  ),
                ],
              ),
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
