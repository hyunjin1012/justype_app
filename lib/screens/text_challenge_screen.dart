import 'package:flutter/material.dart';
import '../widgets/practice_content.dart';
import '../widgets/practice_input_area.dart';
import '../widgets/sentence_display_card.dart';
import '../services/progress_service.dart';
import '../services/sentence_manager.dart';

class TextChallengeScreen extends StatefulWidget {
  const TextChallengeScreen({super.key});

  @override
  State<TextChallengeScreen> createState() => _TextChallengeScreenState();
}

class _TextChallengeScreenState extends State<TextChallengeScreen> {
  final ProgressService _progressService = ProgressService();
  final TextEditingController _controller = TextEditingController();
  final SentenceManager _sentenceManager = SentenceManager();
  final String _feedback = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Challenge'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PracticeContent(
        title: 'Reading Practice',
        heroTag: 'reading_fab',
        sentenceManager: _sentenceManager,
        // Use the reusable SentenceDisplayCard widget
        sentenceDisplay: (sentence) => SentenceDisplayCard(
          sentence: sentence,
          textStyle: Theme.of(context).textTheme.titleLarge,
        ),
        // Use the shared input area widget with button state
        inputArea: (controller, checkAnswer, feedback, isCheckButtonEnabled) =>
            PracticeInputArea(
          controller: controller,
          onCheck: checkAnswer,
          feedback: feedback,
          labelText: 'Type the sentence above',
          isCheckButtonEnabled: isCheckButtonEnabled,
        ),
        onRefresh: () {
          // Nothing special needed for reading practice refresh
        },
      ),
    );
  }
}
