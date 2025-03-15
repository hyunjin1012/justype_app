import 'package:flutter/material.dart';
import '../services/gutenberg_service.dart';
import 'package:go_router/go_router.dart';

class ReadingPracticeScreen extends StatefulWidget {
  const ReadingPracticeScreen({super.key});

  @override
  State<ReadingPracticeScreen> createState() => _ReadingPracticeScreenState();
}

class _ReadingPracticeScreenState extends State<ReadingPracticeScreen> {
  final TextEditingController _textController = TextEditingController();
  String _displayedSentence =
      "Type this sentence to practice your reading skills.";
  String _feedback = "";
  String? _selectedSource = 'Books'; // Dropdown selection
  final GutenbergService _gutenbergService =
      GutenbergService(); // Initialize service
  bool _isLoading = false; // Add loading state flag
  String _bookTitle = ""; // Add book title
  String _bookAuthor = ""; // Add book author
  String _currentBookId = ""; // Add book ID for navigation

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
    // Normalize both strings by trimming whitespace and comparing case-insensitively
    final userInput = _textController.text.trim();
    final targetSentence = _displayedSentence.trim();

    print('User input: $userInput');
    print('Target sentence: $targetSentence');
    print('User input length: ${userInput.length}');
    print('Target sentence length: ${targetSentence.length}');

    // Print character codes to debug invisible characters
    print('User input codes: ${userInput.codeUnits}');
    print('Target sentence codes: ${targetSentence.codeUnits}');

    // Try a more flexible comparison
    final normalizedUserInput =
        userInput.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedTarget =
        targetSentence.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    print('Normalized equal: ${normalizedUserInput == normalizedTarget}');

    if (normalizedUserInput == normalizedTarget) {
      setState(() {
        _feedback = "Correct!";
      });
    } else {
      setState(() {
        _feedback = "Try again!";
      });
    }
  }

  void _fetchRandomSentence() async {
    setState(() {
      _isLoading = true; // Set loading to true when starting fetch
      _feedback = ""; // Clear previous feedback
      _textController.clear(); // Clear text input
    });

    if (_selectedSource == 'AI') {
      // Fetch a random sentence from AI
      setState(() {
        _displayedSentence = "This is a random sentence from AI.";
        _bookTitle = "AI Generated";
        _bookAuthor = "AI";
        _currentBookId = ""; // No book ID for AI
        _isLoading = false; // Set loading to false when done
      });
    } else {
      // Fetch a random sentence from Books using GutenbergService
      try {
        var result = await _gutenbergService.fetchRandomSentence();
        setState(() {
          // Clean the sentence by replacing all whitespace sequences with a single space
          _displayedSentence = (result['sentence'] ?? "No sentence found")
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          _bookTitle = result['title'] ?? "Unknown Title";
          _bookAuthor = result['author'] ?? "Unknown Author";
          _currentBookId = result['bookId'] ?? ""; // Store book ID
          _isLoading = false; // Set loading to false when done
        });
      } catch (e) {
        if (mounted && context.mounted) {
          setState(() {
            _displayedSentence = "Error fetching sentence: $e";
            _bookTitle = "";
            _bookAuthor = "";
            _currentBookId = "";
            _isLoading = false; // Set loading to false even on error
          });
        }
      }
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
                      DropdownButton<String>(
                        value: _selectedSource,
                        items: <String>['AI', 'Books'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedSource = newValue;
                            _fetchRandomSentence(); // Fetch new sentence when changed
                          });
                        },
                      ),
                      const SizedBox(height: 32),
                      _isLoading
                          ? const CircularProgressIndicator() // Show loading indicator
                          : Column(
                              children: [
                                if (_bookTitle.isNotEmpty ||
                                    _bookAuthor.isNotEmpty)
                                  InkWell(
                                    onTap: _currentBookId.isNotEmpty
                                        ? _navigateToBookDetail
                                        : null,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'From: $_bookTitle${_bookAuthor.isNotEmpty ? ' by $_bookAuthor' : ''}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    decoration: _currentBookId
                                                            .isNotEmpty
                                                        ? TextDecoration
                                                            .underline
                                                        : null,
                                                    color: _currentBookId
                                                            .isNotEmpty
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                        : null,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          if (_currentBookId.isNotEmpty)
                                            const SizedBox(width: 4),
                                          if (_currentBookId.isNotEmpty)
                                            const Icon(Icons.open_in_new,
                                                size: 16),
                                        ],
                                      ),
                                    ),
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
                      Text(
                        _feedback,
                        style: TextStyle(
                          color: _feedback == "Correct!"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _fetchRandomSentence,
        tooltip: 'Get New Sentence',
        heroTag: 'reading_fab',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
