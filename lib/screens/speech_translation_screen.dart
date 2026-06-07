import 'package:flutter/material.dart';
import '../services/speech_translation_service.dart';
import '../services/practice_service.dart';
import '../services/progress_service.dart';
import '../services/feedback_service.dart';
import '../widgets/speech_input_area.dart';
import '../widgets/sentence_display_card.dart';
import '../widgets/enhanced_feedback.dart';
import '../widgets/app_surface.dart';
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
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _textController = TextEditingController();

  String _sourcePrompt = '';
  String _recognizedText = '';
  String _translatedText = '';
  String _feedback = '';
  bool _isCheckButtonEnabled = false;
  bool _isRecordButtonEnabled = true;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _selectedLanguage = 'es';
  String _selectedScenario = 'All';
  List<String> _scenarios = ['All'];
  String _errorMessage = '';
  DateTime? _sessionStartedAt;

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
    _feedbackService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAvailability();
    });
  }

  void _checkAvailability() {
    _initializeSpeechService();
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
        });
        await _loadTranslationPrompt();
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

  Future<void> _loadTranslationPrompt() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _sourcePrompt = '';
      _recognizedText = '';
      _translatedText = '';
      _textController.clear();
      _feedback = '';
      _isCheckButtonEnabled = false;
      _isRecordButtonEnabled = true;
      _sessionStartedAt = DateTime.now();
    });

    try {
      final scenarios = await _speechService.getScenarios();
      await _speechService.preparePrompt();

      if (!mounted) return;

      setState(() {
        _scenarios = scenarios;
        if (!_scenarios.contains(_selectedScenario)) {
          _selectedScenario = 'All';
        }
        _sourcePrompt = _speechService.sourcePromptText;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load a local translation prompt: $e';
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
      _isProcessing = true;
    });

    try {
      await _speechService.stopListening();
      setState(() {
        _isListening = false;
        _isLoading = false;
        _isProcessing = false;
        _recognizedText = _speechService.lastRecognizedWords;
        _translatedText = _speechService.translatedText;
        _isCheckButtonEnabled = true;
        _isRecordButtonEnabled = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error stopping speech recognition: $e';
        _isLoading = false;
        _isProcessing = false;
      });
    }
  }

  void _checkAnswer() async {
    final userInput = _textController.text;
    if (userInput.isEmpty || _translatedText.isEmpty) return;

    final isCorrect = _practiceService.checkAnswer(userInput, _translatedText);
    final wordCount = _countWords(_translatedText);
    final elapsedSeconds = _elapsedSeconds();

    if (isCorrect) {
      await _feedbackService.playCorrectSound();
      await _progressService.completeExercise(
        practiceType: 'translation',
        prompt: _translatedText,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );
      if (!mounted) return;
      setState(() {
        _feedback = _buildCompletionMessage(_translatedText);
        _isCheckButtonEnabled = false;
        _isRecordButtonEnabled = false;
      });
    } else {
      await _progressService.recordAnswerAttempt(
        false,
        practiceType: 'translation',
        prompt: _translatedText,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );
      await _feedbackService.playWrongSound();
      if (!mounted) return;
      setState(() {
        _feedback = "Not quite right. Try again or record a new sentence.";
        _isCheckButtonEnabled = true;
        _isRecordButtonEnabled = false;
      });
    }
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

  void _clearState() async {
    await _feedbackService.playLoadSound();
    await _loadTranslationPrompt();
  }

  void _onLanguageChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedLanguage = value;
        _selectedScenario = 'All';
        _sourcePrompt = '';
        _recognizedText = '';
        _translatedText = '';
      });
      _speechService.setLanguages(value, 'en');
      _loadTranslationPrompt();
    }
  }

  void _onScenarioChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedScenario = value;
        _sourcePrompt = '';
        _recognizedText = '';
        _translatedText = '';
      });
      _speechService.setScenario(value);
      _loadTranslationPrompt();
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
    _feedbackService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation Practice'),
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
                    AppSurface(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _initializeSpeechService,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Language selection
                  AppSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Source Language',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedLanguage,
                          items: _languages.entries.map((entry) {
                            return DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: _isLoading ? null : _onLanguageChanged,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Scenario',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedScenario,
                          items: _scenarios.map((scenario) {
                            return DropdownMenuItem(
                              value: scenario,
                              child: Text(scenario),
                            );
                          }).toList(),
                          onChanged: _isLoading ? null : _onScenarioChanged,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_sourcePrompt.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: AppSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Source Prompt',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(_sourcePrompt),
                          ],
                        ),
                      ),
                    ),

                  // Record button
                  ElevatedButton.icon(
                    onPressed: (_isLoading || !_isRecordButtonEnabled)
                        ? null
                        : _isListening
                            ? _stopListening
                            : _startListening,
                    icon: Icon(_isListening ? Icons.stop : Icons.mic),
                    label: Text(_isListening
                        ? 'Stop Recording'
                        : 'Record Source Prompt'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor:
                          _isListening ? Colors.red.shade100 : null,
                    ),
                  ),

                  if (_isLoading) ...[
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                    Text(
                      _isProcessing
                          ? 'Processing your speech...'
                          : 'Initializing speech recognition...',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ] else if (_isListening) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Start speaking now...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  // Recognized text
                  if (_recognizedText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: AppSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You Said',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(_recognizedText),
                          ],
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

          // Input area and feedback - stays at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SpeechInputArea(
                  controller: _textController,
                  onCheck: _checkAnswer,
                  feedback: _feedback,
                  labelText: 'Type or speak the translated sentence',
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
        tooltip: 'New Prompt',
        icon: const Icon(Icons.refresh),
        label: const Text('New'),
      ),
    );
  }
}
