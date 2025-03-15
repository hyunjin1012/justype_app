import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/practice_service.dart';
import 'package:go_router/go_router.dart';

class ListeningPracticeScreen extends StatefulWidget {
  const ListeningPracticeScreen({super.key});

  @override
  State<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen> {
  final TextEditingController _textController = TextEditingController();
  // Store sentences for each source
  String _booksSentence = "";
  String _aiSentence = "This is a random sentence from AI.";
  String _spokenSentence = "";
  String _feedback = "";
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  String _selectedSource = 'Books';
  final PracticeService _practiceService = PracticeService();
  bool _isLoading = false;
  bool _isTextVisible = false;
  String _bookTitle = "";
  String _bookAuthor = "";
  String _currentBookId = "";

  @override
  void initState() {
    super.initState();
    _initTts();
    // Fetch a random sentence when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRandomSentence();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // Initialize TTS settings
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
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

    await _flutterTts.speak(_spokenSentence);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Speaking the sentence...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _checkAnswer() {
    bool isCorrect =
        _practiceService.checkAnswer(_textController.text, _spokenSentence);

    setState(() {
      _feedback = isCorrect ? "Correct!" : "Try again!";
    });
  }

  void _fetchRandomSentence() async {
    // Only fetch if we don't already have content for this source
    if ((_selectedSource == 'Books' && _booksSentence.isEmpty) ||
        (_selectedSource == 'AI' && _aiSentence.isEmpty)) {
      setState(() {
        _isLoading = true;
        _feedback = "";
        _textController.clear();
      });

      final result = await _practiceService.fetchRandomContent(
          _selectedSource, _isLoading);

      if (mounted) {
        setState(() {
          if (_selectedSource == 'Books') {
            _booksSentence = result['content'];
          } else {
            _aiSentence = result['content'];
          }

          _spokenSentence =
              _selectedSource == 'Books' ? _booksSentence : _aiSentence;
          _bookTitle = result['bookTitle'];
          _bookAuthor = result['bookAuthor'];
          _currentBookId = result['currentBookId'];
          _isLoading = false;
        });
      }
    } else {
      // Just switch to the existing content
      setState(() {
        _spokenSentence =
            _selectedSource == 'Books' ? _booksSentence : _aiSentence;
        _feedback = "";
        _textController.clear();
      });
    }
  }

  void _toggleTextVisibility() {
    setState(() {
      _isTextVisible = !_isTextVisible;
    });
  }

  void _navigateToBookDetail() {
    if (_currentBookId.isNotEmpty) {
      GoRouter.of(context).push('/book/$_currentBookId');
    }
  }

  void _fetchNewSentence() async {
    setState(() {
      _isLoading = true;
      _feedback = "";
      _textController.clear();
    });

    final result =
        await _practiceService.fetchRandomContent(_selectedSource, _isLoading);

    if (mounted) {
      setState(() {
        if (_selectedSource == 'Books') {
          _booksSentence = result['content'];
        } else {
          _aiSentence = result['content'];
        }

        _spokenSentence =
            _selectedSource == 'Books' ? _booksSentence : _aiSentence;
        _bookTitle = result['bookTitle'];
        _bookAuthor = result['bookAuthor'];
        _currentBookId = result['currentBookId'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Practice'),
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
                      // Use shared source selector
                      _practiceService.buildSourceSelector(
                        _selectedSource,
                        (newSource) {
                          setState(() {
                            _selectedSource = newSource;
                            _fetchRandomSentence();
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Column(
                              children: [
                                // Use shared book source info widget
                                _practiceService.buildBookSourceInfo(
                                  context,
                                  _bookTitle,
                                  _bookAuthor,
                                  _currentBookId,
                                  _navigateToBookDetail,
                                  _selectedSource,
                                ),
                                ElevatedButton.icon(
                                  onPressed: _speakSentence,
                                  icon: Icon(_isSpeaking
                                      ? Icons.stop
                                      : Icons.volume_up),
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
                                  label: Text(_isTextVisible
                                      ? 'Hide Text'
                                      : 'Show Text'),
                                ),
                                if (_isTextVisible)
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Card(
                                      elevation: 4,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: SingleChildScrollView(
                                          child: Text(
                                            _spokenSentence,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
            // Fixed bottom input area
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
                      labelText: 'Type what you hear',
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _fetchNewSentence,
        tooltip: 'Get New Sentence',
        heroTag: 'listening_fab',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
