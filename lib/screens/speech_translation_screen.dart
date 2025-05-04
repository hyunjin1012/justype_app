import 'package:flutter/material.dart';
import '../services/speech_translation_service.dart';
import '../services/practice_service.dart';
import '../services/progress_service.dart';
import '../widgets/practice_input_area.dart';
import '../widgets/sentence_display_card.dart';
import '../widgets/enhanced_feedback.dart';
import 'package:go_router/go_router.dart';

class SpeechTranslationScreen extends StatefulWidget {
  const SpeechTranslationScreen({super.key});

  @override
  State<SpeechTranslationScreen> createState() =>
      _SpeechTranslationScreenState();
}

class _SpeechTranslationScreenState extends State<SpeechTranslationScreen> {
  late final SpeechTranslationService _speechService;
  final PracticeService _practiceService = PracticeService();
  final ProgressService _progressService = ProgressService();
  final TextEditingController _textController = TextEditingController();

  String _recognizedText = '';
  String _translatedText = '';
  String _feedback = '';
  bool _isCheckButtonEnabled = true;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isListening = false;
  String _selectedLanguage = 'en';
  String _errorMessage = '';

  final Map<String, String> _languages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'ja': 'Japanese',
    'zh': 'Chinese',
    'ru': 'Russian',
    'ar': 'Arabic',
    'ko': 'Korean',
  };

  @override
  void initState() {
    super.initState();
    _speechService = SpeechTranslationService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeechService();
    });
  }

  Future<void> _initializeSpeechService() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isAvailable = await _speechService.initialize();

      if (!mounted) return;

      if (isAvailable) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      } else {
        final error = _speechService.error ?? 'Unknown error occurred';
        setState(() {
          _errorMessage = '''
Failed to initialize speech recognition: $error

Please ensure:
1. You are running the app on a physical device (not an emulator)
2. Microphone permissions are enabled in your device settings
3. Your device supports speech recognition

Tap the refresh button to try again.''';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '''
Failed to initialize speech recognition: $e

Please ensure:
1. You are running the app on a physical device (not an emulator)
2. Microphone permissions are enabled in your device settings
3. Your device supports speech recognition

Tap the refresh button to try again.''';
        _isLoading = false;
      });
    }
  }

  Future<void> _startListening() async {
    if (!_isInitialized) {
      await _initializeSpeechService();
      if (!_isInitialized) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _speechService.startListening();
      setState(() {
        _isListening = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error starting speech recognition: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _stopListening() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
        _isLoading = false;
        _recognizedText = _speechService.lastRecognizedWords;
        _translatedText = _speechService.translatedText;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error stopping speech recognition: $e';
        _isLoading = false;
      });
    }
  }

  void _checkAnswer() {
    final userInput = _textController.text;
    if (userInput.isEmpty || _translatedText.isEmpty) return;

    final isCorrect = _practiceService.checkAnswer(userInput, _translatedText);
    setState(() {
      _feedback = isCorrect
          ? "Correct! Great job."
          : "Not quite right. Try again or record a new sentence.";
      _isCheckButtonEnabled = !isCorrect;
    });

    if (isCorrect) {
      _progressService.completeExercise(practiceType: 'translation');
    }
  }

  void _clearState() {
    setState(() {
      _recognizedText = '';
      _translatedText = '';
      _textController.clear();
      _feedback = '';
      _isCheckButtonEnabled = true;
    });
  }

  void _onLanguageChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedLanguage = value;
        _recognizedText = '';
        _translatedText = '';
      });
      _speechService.setLanguages(value, 'en');
    }
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
                correctSentence: _translatedText,
                isCorrect: _practiceService.checkAnswer(
                  _textController.text,
                  _translatedText,
                ),
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
  void dispose() {
    _speechService.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Translation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/challenges'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (_errorMessage.isNotEmpty)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _initializeSpeechService,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Language selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Your Language',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedLanguage,
                            items: _languages.entries.map((entry) {
                              return DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                            onChanged: _isLoading ? null : _onLanguageChanged,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Record button
                  ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : _isListening
                            ? _stopListening
                            : _startListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(
                        _isListening ? 'Stop Recording' : 'Start Recording'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor:
                          _isListening ? Colors.red.shade100 : null,
                    ),
                  ),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),

                  // Recognized text
                  if (_recognizedText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recognized Text:',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(_recognizedText),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Translated text
                  if (_translatedText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: SentenceDisplayCard(
                        sentence: _translatedText,
                        textStyle: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Input area
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                PracticeInputArea(
                  controller: _textController,
                  onCheck: _checkAnswer,
                  feedback: _feedback,
                  labelText: 'Type the translated sentence',
                  isCheckButtonEnabled:
                      _isCheckButtonEnabled && _translatedText.isNotEmpty,
                ),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _feedback,
                    style: TextStyle(
                      color: _practiceService.checkAnswer(
                        _textController.text,
                        _translatedText,
                      )
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _clearState,
        tooltip: 'New Translation',
        icon: const Icon(Icons.refresh),
        label: const Text('New'),
      ),
    );
  }
}
