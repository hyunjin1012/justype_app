import 'package:flutter/material.dart';
import '../services/gutenberg_service.dart';
import '../services/practice_service.dart';
import 'package:go_router/go_router.dart';

class ReadingPracticeScreen extends StatefulWidget {
  const ReadingPracticeScreen({super.key});

  @override
  State<ReadingPracticeScreen> createState() => _ReadingPracticeScreenState();
}

class _ReadingPracticeScreenState extends State<ReadingPracticeScreen> {
  final TextEditingController _textController = TextEditingController();
  // Store sentences for each source
  String _booksSentence = "";
  String _aiSentence = "This is a random sentence from AI.";
  String _displayedSentence = "";
  String _feedback = "";
  String _selectedSource = 'Books';
  final PracticeService _practiceService = PracticeService();
  bool _isLoading = false;
  String _bookTitle = "";
  String _bookAuthor = "";
  String _currentBookId = "";

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
    bool isCorrect =
        _practiceService.checkAnswer(_textController.text, _displayedSentence);

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

          _displayedSentence =
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
        _displayedSentence =
            _selectedSource == 'Books' ? _booksSentence : _aiSentence;
        _feedback = "";
        _textController.clear();
      });
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

        _displayedSentence =
            _selectedSource == 'Books' ? _booksSentence : _aiSentence;
        _bookTitle = result['bookTitle'];
        _bookAuthor = result['bookAuthor'];
        _currentBookId = result['currentBookId'];
        _isLoading = false;
      });
    }
  }

  void _navigateToBookDetail() {
    if (_currentBookId.isNotEmpty) {
      GoRouter.of(context).push('/book/$_currentBookId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Practice'),
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
                            // This will use cached content if available
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
                                Card(
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        _displayedSentence,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 32),
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
                      labelText: 'Type the sentence above',
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
        heroTag: 'reading_fab',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
