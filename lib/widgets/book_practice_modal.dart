import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/practice_service.dart';
import '../services/tts_service.dart';
import '../widgets/practice_input_area.dart';
import '../widgets/sentence_display_card.dart';
import '../widgets/visibility_toggle.dart';
import '../widgets/practice_mode_selector.dart';

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
  String _currentSentence = "";
  String _feedback = "";
  bool _isListeningMode = false;
  final TtsService _ttsService = TtsService();
  bool _isTextVisible = true;
  List<String> _sentences = [];
  final PracticeService _practiceService = PracticeService();

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _extractSentences();
    _getRandomSentence();
  }

  @override
  void dispose() {
    _textController.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  void _extractSentences() {
    // Split the book content into sentences
    final content = widget.book.content;
    final rawSentences = content.split(RegExp(r'(?<=[.!?])\s+'));

    // Filter out empty sentences and very short ones
    _sentences = rawSentences
        .where((s) => s.trim().length > 20 && s.trim().length < 200)
        .map((s) => s.replaceAll(RegExp(r'\s+'), ' ').trim())
        .toList();
  }

  void _getRandomSentence() {
    if (_sentences.isEmpty) {
      setState(() {
        _currentSentence = "No suitable sentences found in this book.";
      });
      return;
    }

    setState(() {
      _feedback = "";
      _textController.clear();
      _currentSentence =
          _sentences[DateTime.now().millisecondsSinceEpoch % _sentences.length];
    });
  }

  void _speakSentence() {
    _ttsService.speak(_currentSentence, onStateChange: () {
      setState(() {});
    });
  }

  void _checkAnswer() {
    bool isCorrect =
        _practiceService.checkAnswer(_textController.text, _currentSentence);

    setState(() {
      _feedback = isCorrect ? "Correct!" : "Try again!";
    });
  }

  void _toggleMode() {
    setState(() {
      _isListeningMode = !_isListeningMode;
      _isTextVisible = !_isListeningMode;
      _feedback = "";
      _textController.clear();
    });
  }

  void _toggleTextVisibility() {
    setState(() {
      _isTextVisible = !_isTextVisible;
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
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_isListeningMode) ...[
                      _ttsService.buildSpeakButton(
                          context, _speakSentence, _ttsService.isSpeaking),
                      const SizedBox(height: 16),
                      VisibilityToggle(
                        isVisible: _isTextVisible,
                        onToggle: _toggleTextVisibility,
                      ),
                    ],
                    if (_isTextVisible || !_isListeningMode)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SentenceDisplayCard(sentence: _currentSentence),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Use the shared PracticeInputArea widget
          PracticeInputArea(
            controller: _textController,
            onCheck: _checkAnswer,
            feedback: _feedback,
            labelText: 'Type what you see/hear',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getRandomSentence,
        tooltip: 'Get New Sentence',
        heroTag: 'book_practice_fab',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
