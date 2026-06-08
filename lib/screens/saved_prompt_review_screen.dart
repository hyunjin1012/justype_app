import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/feedback_service.dart';
import '../services/practice_service.dart';
import '../services/progress_service.dart';
import '../services/purchase_service.dart';
import '../services/saved_prompt_service.dart';
import '../widgets/app_surface.dart';
import '../widgets/enhanced_feedback.dart';
import '../widgets/plus_purchase_sheet.dart';
import '../widgets/practice_session_scaffold.dart';
import '../widgets/sentence_display_card.dart';
import '../widgets/speech_input_area.dart';

class SavedPromptReviewScreen extends StatefulWidget {
  const SavedPromptReviewScreen({super.key});

  @override
  State<SavedPromptReviewScreen> createState() =>
      _SavedPromptReviewScreenState();
}

class _SavedPromptReviewScreenState extends State<SavedPromptReviewScreen> {
  final TextEditingController _textController = TextEditingController();
  final PracticeService _practiceService = PracticeService();
  final ProgressService _progressService = ProgressService();
  final FeedbackService _feedbackService = FeedbackService();

  bool _isLoading = true;
  bool _isCheckButtonEnabled = true;
  bool _isComplete = false;
  String _feedback = '';
  int _currentIndex = 0;
  DateTime? _sessionStartedAt;
  final Set<String> _masteredPromptIds = {};

  @override
  void initState() {
    super.initState();
    _feedbackService.initialize();
    _loadSavedPrompts();
  }

  Future<void> _loadSavedPrompts() async {
    final savedPromptService =
        Provider.of<SavedPromptService>(context, listen: false);
    await savedPromptService.loadSavedPrompts();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _sessionStartedAt = DateTime.now();
    });
  }

  Future<void> _checkAnswer(SavedPrompt savedPrompt) async {
    final userInput = _textController.text;
    final prompt = savedPrompt.prompt;
    if (userInput.isEmpty || prompt.isEmpty) return;

    final isCorrect = _practiceService.checkAnswer(userInput, prompt);
    final wordCount = _countWords(prompt);
    final elapsedSeconds = _elapsedSeconds();

    if (isCorrect) {
      await _feedbackService.playCorrectSound();
      await _progressService.completeExercise(
        practiceType: 'saved',
        prompt: prompt,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );

      if (!mounted) return;

      setState(() {
        _masteredPromptIds.add(savedPrompt.id);
        _feedback = 'Correct! $wordCount words matched in ${elapsedSeconds}s.';
        _isCheckButtonEnabled = false;
      });
    } else {
      await _progressService.recordAnswerAttempt(
        false,
        practiceType: 'saved',
        prompt: prompt,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );
      await _feedbackService.playWrongSound();

      if (!mounted) return;

      setState(() {
        _feedback = 'Not quite right. Try this prompt once more.';
        _isCheckButtonEnabled = true;
      });
    }
  }

  void _goToNextPrompt(int promptCount) {
    if (_currentIndex >= promptCount - 1) {
      setState(() {
        _isComplete = true;
      });
      return;
    }

    setState(() {
      _currentIndex++;
      _resetPromptState();
    });
  }

  void _reviewAgain() {
    setState(() {
      _currentIndex = 0;
      _isComplete = false;
      _masteredPromptIds.clear();
      _resetPromptState();
    });
  }

  void _resetPromptState() {
    _textController.clear();
    _feedback = '';
    _isCheckButtonEnabled = true;
    _sessionStartedAt = DateTime.now();
  }

  void _showEnhancedFeedback(String prompt) {
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
  void dispose() {
    _textController.dispose();
    _feedbackService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PurchaseService, SavedPromptService>(
      builder: (context, purchaseService, savedPromptService, child) {
        if (_isLoading || !savedPromptService.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!purchaseService.isPlusUnlocked) {
          return _buildLockedScreen(context);
        }

        final prompts = savedPromptService.savedPrompts;
        if (prompts.isEmpty) {
          return _buildEmptyScreen(context);
        }

        if (_isComplete) {
          return _buildCompleteScreen(context, prompts.length);
        }

        final safeIndex = _currentIndex.clamp(0, prompts.length - 1);
        final savedPrompt = prompts[safeIndex];
        final prompt = savedPrompt.prompt;
        final progressText = '${safeIndex + 1} of ${prompts.length}';

        return PracticeSessionScaffold(
          title: 'Review Queue',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => GoRouter.of(context).go('/challenges/saved'),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSurface(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.45),
                child: Row(
                  children: [
                    Icon(
                      Icons.view_list,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        progressText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Text(
                      savedPrompt.sourceLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
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
            onCheck: () => _checkAnswer(savedPrompt),
            labelText: 'Type or speak this prompt',
            isCheckButtonEnabled: _isCheckButtonEnabled,
          ),
          feedback: _feedback,
          isFeedbackCorrect: _feedback.isEmpty
              ? null
              : _practiceService.checkAnswer(
                  _textController.text,
                  prompt,
                ),
          onShowDetails:
              _feedback.isEmpty ? null : () => _showEnhancedFeedback(prompt),
          onNext: () => _goToNextPrompt(prompts.length),
          nextLabel:
              safeIndex >= prompts.length - 1 ? 'Finish review' : 'Next prompt',
        );
      },
    );
  }

  Widget _buildLockedScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/challenges/saved'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppSurface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_list,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Review Queue is Plus',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock Plus to practice saved and custom prompts as a queue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _showPlusSheet,
                    icon: const Icon(Icons.workspace_premium),
                    label: const Text('Unlock Plus'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Queue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/challenges/saved'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bookmark_add_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'No prompts to review',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Save or add prompts first, then come back to review them.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteScreen(BuildContext context, int promptCount) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Complete'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/challenges/saved'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppSurface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 52,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Review complete',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_masteredPromptIds.length} of $promptCount prompts matched.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _reviewAgain,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Review Again'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () =>
                        GoRouter.of(context).go('/challenges/saved'),
                    child: const Text('Back to Saved Prompts'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlusSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const PlusPurchaseSheet(),
    );
  }
}
