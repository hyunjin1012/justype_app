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
import '../widgets/save_prompt_action.dart';
import '../widgets/sentence_display_card.dart';
import '../widgets/speech_input_area.dart';

class SavedPromptPracticeScreen extends StatefulWidget {
  final String promptId;

  const SavedPromptPracticeScreen({
    super.key,
    required this.promptId,
  });

  @override
  State<SavedPromptPracticeScreen> createState() =>
      _SavedPromptPracticeScreenState();
}

class _SavedPromptPracticeScreenState extends State<SavedPromptPracticeScreen> {
  final TextEditingController _textController = TextEditingController();
  final PracticeService _practiceService = PracticeService();
  final ProgressService _progressService = ProgressService();
  final FeedbackService _feedbackService = FeedbackService();

  bool _isLoading = true;
  bool _isCheckButtonEnabled = true;
  String _feedback = '';
  DateTime? _sessionStartedAt;

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

  Future<void> _checkAnswer(String prompt) async {
    final userInput = _textController.text;
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
        _feedback = 'Not quite right. Try this saved prompt once more.';
        _isCheckButtonEnabled = true;
      });
    }
  }

  void _resetSession() {
    setState(() {
      _textController.clear();
      _feedback = '';
      _isCheckButtonEnabled = true;
      _sessionStartedAt = DateTime.now();
    });
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

        final savedPrompt = savedPromptService.promptById(widget.promptId);
        if (savedPrompt == null) {
          return _buildMissingPromptScreen(context);
        }

        final prompt = savedPrompt.prompt;

        return PracticeSessionScaffold(
          title: 'Saved Prompt',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => GoRouter.of(context).go('/challenges/saved'),
          ),
          actions: [
            SavePromptAction(
              prompt: prompt,
              sourceLabel: savedPrompt.sourceLabel,
            ),
          ],
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSurface(
                color:
                    Theme.of(context).colorScheme.primaryContainer.withValues(
                          alpha: 0.45,
                        ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        savedPrompt.sourceLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
            onCheck: () => _checkAnswer(prompt),
            labelText: 'Type or speak this saved prompt',
            isCheckButtonEnabled: _isCheckButtonEnabled,
          ),
          feedback: _feedback,
          isFeedbackCorrect: _feedback.isEmpty
              ? null
              : _practiceService.checkAnswer(_textController.text, prompt),
          onShowDetails:
              _feedback.isEmpty ? null : () => _showEnhancedFeedback(prompt),
          onNext: _resetSession,
          nextLabel: 'Try again',
        );
      },
    );
  }

  Widget _buildLockedScreen(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Prompt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/challenges'),
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
                  Icons.bookmarks_outlined,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Saved prompts are Plus',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock Plus to save and replay favorite prompts.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildMissingPromptScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Prompt'),
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
              const Icon(Icons.bookmark_remove_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'This prompt is no longer saved',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => GoRouter.of(context).go('/challenges/saved'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Saved Prompts'),
              ),
            ],
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
