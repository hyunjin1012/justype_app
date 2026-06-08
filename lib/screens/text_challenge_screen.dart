import 'package:flutter/material.dart';
import '../widgets/practice_content.dart';
import '../widgets/speech_input_area.dart';
import '../widgets/sentence_display_card.dart';
import '../services/sentence_manager.dart';
import 'package:go_router/go_router.dart';

class TextChallengeScreen extends StatefulWidget {
  const TextChallengeScreen({super.key});

  @override
  State<TextChallengeScreen> createState() => _TextChallengeScreenState();
}

class _TextChallengeScreenState extends State<TextChallengeScreen> {
  final SentenceManager _sentenceManager = SentenceManager();

  @override
  Widget build(BuildContext context) {
    return PracticeContent(
      title: 'Typing',
      sentenceManager: _sentenceManager,
      // Use the reusable SentenceDisplayCard widget
      sentenceDisplay: (sentence) => SentenceDisplayCard(
        sentence: sentence,
        textStyle: Theme.of(context).textTheme.titleLarge,
      ),
      // Use the speech input area widget instead of typing
      inputArea: (controller, checkAnswer, isCheckButtonEnabled) =>
          SpeechInputArea(
        controller: controller,
        onCheck: checkAnswer,
        labelText: 'Type or speak the prompt above',
        isCheckButtonEnabled: isCheckButtonEnabled,
      ),
      onRefresh: () {
        // Nothing special needed for reading practice refresh
      },
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => GoRouter.of(context).go('/home'),
      ),
    );
  }
}
