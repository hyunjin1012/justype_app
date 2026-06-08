import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/feedback_service.dart';
import '../services/practice_service.dart';
import '../services/progress_service.dart';
import '../services/speech_translation_service.dart';
import '../widgets/app_surface.dart';
import '../widgets/enhanced_feedback.dart';
import '../widgets/practice_session_scaffold.dart';
import '../widgets/save_prompt_action.dart';
import '../widgets/speech_input_area.dart';

class SpeechTranslationScreen extends StatefulWidget {
  const SpeechTranslationScreen({super.key});

  @override
  State<SpeechTranslationScreen> createState() =>
      _SpeechTranslationScreenState();
}

class _SpeechTranslationScreenState extends State<SpeechTranslationScreen> {
  late final SpeechTranslationService _phraseService;
  final PracticeService _practiceService = PracticeService();
  final ProgressService _progressService = ProgressService();
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _textController = TextEditingController();

  String _sourcePrompt = '';
  String _sourceRomanization = '';
  String _targetPrompt = '';
  String _feedback = '';
  bool _isCheckButtonEnabled = false;
  bool _isLoading = false;
  String _selectedLanguage = 'es';
  String _selectedScenario = 'All';
  List<String> _scenarios = ['All'];
  String _errorMessage = '';
  DateTime? _sessionStartedAt;

  final Map<String, String> _languages = {
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'ja': 'Japanese',
    'zh': 'Chinese',
    'ru': 'Russian',
    'ar': 'Arabic',
    'ko': 'Korean',
    'en': 'English',
  };

  @override
  void initState() {
    super.initState();
    _phraseService = SpeechTranslationService();
    _feedbackService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPhrasePrompt();
    });
  }

  Future<void> _loadPhrasePrompt() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _sourcePrompt = '';
      _sourceRomanization = '';
      _targetPrompt = '';
      _textController.clear();
      _feedback = '';
      _errorMessage = '';
      _isCheckButtonEnabled = false;
      _sessionStartedAt = DateTime.now();
    });

    try {
      final scenarios = await _phraseService.getScenarios();
      await _phraseService.preparePrompt();

      if (!mounted) return;

      setState(() {
        _scenarios = scenarios;
        if (!_scenarios.contains(_selectedScenario)) {
          _selectedScenario = 'All';
        }
        _sourcePrompt = _phraseService.sourcePromptText;
        _sourceRomanization = _phraseService.sourcePromptRomanization;
        _targetPrompt = _phraseService.targetPromptText;
        _isCheckButtonEnabled = _targetPrompt.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _checkAnswer() async {
    final userInput = _textController.text;
    if (userInput.isEmpty || _targetPrompt.isEmpty) return;

    final isCorrect = _practiceService.checkAnswer(userInput, _targetPrompt);
    final wordCount = _countWords(_targetPrompt);
    final elapsedSeconds = _elapsedSeconds();

    if (isCorrect) {
      await _feedbackService.playCorrectSound();
      await _progressService.completeExercise(
        practiceType: 'translation',
        prompt: _targetPrompt,
        promptKey: _phraseService.currentPromptPracticeKey,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );
      if (!mounted) return;
      setState(() {
        _feedback = _buildCompletionMessage(_targetPrompt);
        _isCheckButtonEnabled = false;
      });
    } else {
      await _progressService.recordAnswerAttempt(
        false,
        practiceType: 'translation',
        prompt: _targetPrompt,
        promptKey: _phraseService.currentPromptPracticeKey,
        wordCount: wordCount,
        elapsedSeconds: elapsedSeconds,
      );
      await _feedbackService.playWrongSound();
      if (!mounted) return;
      setState(() {
        _feedback = 'Not quite right. Try this translation once more.';
        _isCheckButtonEnabled = true;
      });
    }
  }

  String _buildCompletionMessage(String sentence) {
    final startedAt = _sessionStartedAt;
    if (startedAt == null) {
      return 'Correct! Great job.';
    }

    final elapsedSeconds = _elapsedSeconds();
    final wordCount = _countWords(sentence);

    return 'Correct! $wordCount words matched in ${elapsedSeconds}s.';
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

  Future<void> _nextPhrase() async {
    await _feedbackService.playLoadSound();
    await _loadPhrasePrompt();
  }

  void _onLanguageChanged(String? value) {
    if (value == null) return;

    setState(() {
      _selectedLanguage = value;
      _selectedScenario = 'All';
    });
    _phraseService.setLanguages(value, 'en');
    _loadPhrasePrompt();
  }

  void _onScenarioChanged(String scenario) {
    setState(() {
      _selectedScenario = scenario;
    });
    _phraseService.setScenario(scenario);
    _loadPhrasePrompt();
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
                correctSentence: _targetPrompt,
                isCorrect: _practiceService.checkAnswer(
                  _textController.text,
                  _targetPrompt,
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

  String get _saveSourceLabel {
    final language = _languages[_selectedLanguage] ?? 'Translation';
    final scenario =
        _selectedScenario == 'All' ? 'Translate to English' : _selectedScenario;

    return '$scenario: $language to English';
  }

  @override
  void dispose() {
    _phraseService.dispose();
    _textController.dispose();
    _feedbackService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PracticeSessionScaffold(
      title: 'Translate to English',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => GoRouter.of(context).go('/home'),
      ),
      actions: [
        SavePromptAction(
          prompt: _isLoading ? '' : _targetPrompt,
          sourceLabel: _saveSourceLabel,
        ),
      ],
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage.isNotEmpty) ...[
            AppSurface(
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadPhrasePrompt,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildScenarioPanel(context),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_sourcePrompt.isNotEmpty)
            _buildPhrasePrompt(context),
          if (_targetPrompt.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildPracticeHint(context),
          ],
        ],
      ),
      inputArea: SpeechInputArea(
        controller: _textController,
        onCheck: _checkAnswer,
        labelText: 'Type the English translation',
        isCheckButtonEnabled: _isCheckButtonEnabled && _targetPrompt.isNotEmpty,
      ),
      feedback: _feedback,
      isFeedbackCorrect: _feedback.isEmpty
          ? null
          : _practiceService.checkAnswer(
              _textController.text,
              _targetPrompt,
            ),
      onShowDetails: _feedback.isEmpty ? null : _showEnhancedFeedback,
      onNext: _isLoading ? null : _nextPhrase,
      nextLabel: 'New prompt',
    );
  }

  Widget _buildScenarioPanel(BuildContext context) {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Translation Pack',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              SizedBox(
                width: 142,
                child: DropdownButtonFormField<String>(
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
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final scenario in _scenarios)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(scenario),
                      selected: _selectedScenario == scenario,
                      onSelected: _isLoading
                          ? null
                          : (_) => _onScenarioChanged(scenario),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhrasePrompt(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedScenario == 'All'
                ? 'Translate this to English'
                : 'Translate this $_selectedScenario prompt to English',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _sourcePrompt,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textDirection: _selectedLanguage == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
          ),
          if (_sourceRomanization.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _sourceRomanization,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Read the prompt above, then type or speak its English meaning below.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeHint(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.keyboard_voice,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your answer should be the English translation.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
