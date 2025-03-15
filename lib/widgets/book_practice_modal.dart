import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/book.dart';
import '../services/practice_service.dart';

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
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _isTextVisible = true;
  List<String> _sentences = [];
  final PracticeService _practiceService = PracticeService();

  @override
  void initState() {
    super.initState();
    _initTts();
    _extractSentences();
    _getRandomSentence();
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    });
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

  Future<void> _speakSentence() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() {
        _isSpeaking = false;
      });
      return;
    }

    setState(() {
      _isSpeaking = true;
    });

    await _flutterTts.speak(_currentSentence);
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Reading'),
                  icon: Icon(Icons.menu_book),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Listening'),
                  icon: Icon(Icons.hearing),
                ),
              ],
              selected: {_isListeningMode},
              onSelectionChanged: (Set<bool> selection) {
                _toggleMode();
              },
            ),
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
                      ElevatedButton.icon(
                        onPressed: _speakSentence,
                        icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
                        label: Text(_isSpeaking ? 'Stop' : 'Listen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSpeaking
                              ? Colors.red.shade100
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _toggleTextVisibility,
                        icon: Icon(_isTextVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                        label: Text(_isTextVisible ? 'Hide Text' : 'Show Text'),
                      ),
                    ],
                    if (_isTextVisible || !_isListeningMode)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              _currentSentence,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Type what you see/hear',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: _checkAnswer,
                      child: const Text('Check'),
                    ),
                    // Use shared feedback widget
                    _practiceService.buildFeedbackText(_feedback),
                  ],
                ),
              ],
            ),
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
