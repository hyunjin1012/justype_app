import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/feedback_service.dart';
import '../services/practice_service.dart';
import '../services/progress_service.dart';
import '../widgets/enhanced_feedback.dart';
import '../widgets/practice_session_scaffold.dart';
import '../widgets/sentence_display_card.dart';
import '../widgets/speech_input_area.dart';

class WeakDrillScreen extends StatefulWidget {
  const WeakDrillScreen({super.key});

  @override
  State<WeakDrillScreen> createState() => _WeakDrillScreenState();
}

class _WeakDrillScreenState extends State<WeakDrillScreen> {
  final ProgressService _progressService = ProgressService();
  final PracticeService _practiceService = PracticeService();
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _textController = TextEditingController();

  List<String> _weakPrompts = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isCheckButtonEnabled = true;
  String _feedback = '';
  DateTime? _sessionStartedAt;

  String get _currentPrompt =>
      _weakPrompts.isEmpty ? '' : _weakPrompts[_currentIndex];

  @override
  void initState() {
    super.initState();
    _feedbackService.initialize();
    _loadWeakPrompts();
  }

  @override
  void dispose() {
    _textController.dispose();
    _feedbackService.dispose();
    super.dispose();
  }

  Future<void> _loadWeakPrompts() async {
    await _progressService.loadProgress();

    if (!mounted) return;

    setState(() {
      _weakPrompts = _progressService.getWeakPrompts();
      _currentIndex = 0;
      _isLoading = false;
      _isCheckButtonEnabled = true;
      _feedback = '';
      _textController.clear();
      _sessionStartedAt = DateTime.now();
    });
  }

  Future<void> _checkAnswer() async {
    final prompt = _currentPrompt;
    final userInput = _textController.text;
    if (prompt.isEmpty || userInput.isEmpty) return;

    final isCorrect = _practiceService.checkAnswer(userInput, prompt);
    final wordCount = _countWords(prompt);
    final elapsedSeconds = _elapsedSeconds();

    if (isCorrect) {
      await _feedbackService.playCorrectSound();
      await _progressService.completeExercise(
        practiceType: 'weak',
        prompt: prompt,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );

      if (!mounted) return;

      setState(() {
        _feedback = 'Cleared! $wordCount words matched in ${elapsedSeconds}s.';
        _isCheckButtonEnabled = false;
      });
    } else {
      await _progressService.recordAnswerAttempt(
        false,
        practiceType: 'weak',
        prompt: prompt,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );
      await _feedbackService.playWrongSound();

      if (!mounted) return;

      setState(() {
        _feedback = 'Still needs practice. Try this prompt once more.';
      });
    }
  }

  Future<void> _nextPrompt() async {
    final latestWeakPrompts = _progressService.getWeakPrompts();

    if (!mounted) return;

    setState(() {
      _weakPrompts = latestWeakPrompts;
      if (_weakPrompts.isEmpty) {
        _currentIndex = 0;
      } else {
        _currentIndex = (_currentIndex + 1) % _weakPrompts.length;
      }
      _textController.clear();
      _feedback = '';
      _isCheckButtonEnabled = true;
      _sessionStartedAt = DateTime.now();
    });
  }

  void _showEnhancedFeedback() {
    final prompt = _currentPrompt;
    if (prompt.isEmpty) return;

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
                correctSentence: prompt,
                isCorrect: _practiceService.checkAnswer(
                  _textController.text,
                  prompt,
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

  @override
  Widget build(BuildContext context) {
    final prompt = _currentPrompt;

    if (_isLoading || prompt.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Weak Drills'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => GoRouter.of(context).go('/challenges'),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.green.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No weak prompts yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Missed answers from other modes will appear here for focused review.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => GoRouter.of(context).go('/challenges'),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Challenges'),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }

    return PracticeSessionScaffold(
      title: 'Weak Drills',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => GoRouter.of(context).go('/challenges'),
      ),
      content: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_weakPrompts.length} prompts need review',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SentenceDisplayCard(
            sentence: prompt,
            textStyle: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      inputArea: SpeechInputArea(
        controller: _textController,
        onCheck: _checkAnswer,
        labelText: 'Type or speak this weak prompt',
        isCheckButtonEnabled: _isCheckButtonEnabled,
      ),
      feedback: _feedback,
      isFeedbackCorrect: _feedback.isEmpty
          ? null
          : _practiceService.checkAnswer(
              _textController.text,
              prompt,
            ),
      onShowDetails: _feedback.isEmpty ? null : _showEnhancedFeedback,
      onNext: _nextPrompt,
      nextLabel: 'Next prompt',
    );
  }
}
