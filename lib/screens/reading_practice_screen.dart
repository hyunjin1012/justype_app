import 'package:flutter/material.dart';
import '../widgets/practice_content.dart';
import '../widgets/practice_input_area.dart';
import '../widgets/sentence_display_card.dart';

class ReadingPracticeScreen extends StatefulWidget {
  const ReadingPracticeScreen({super.key});

  @override
  State<ReadingPracticeScreen> createState() => _ReadingPracticeScreenState();
}

class _ReadingPracticeScreenState extends State<ReadingPracticeScreen> {
  @override
  Widget build(BuildContext context) {
    return PracticeContent(
      title: 'Reading Practice',
      heroTag: 'reading_fab',
      // Use the reusable SentenceDisplayCard widget
      sentenceDisplay: (sentence) => SentenceDisplayCard(
        sentence: sentence,
        textStyle: Theme.of(context).textTheme.titleLarge,
      ),
      // Use the shared input area widget
      inputArea: (controller, checkAnswer, feedback) => PracticeInputArea(
        controller: controller,
        onCheck: checkAnswer,
        feedback: feedback,
        labelText: 'Type the sentence above',
      ),
      onRefresh: () {
        // Any additional refresh logic specific to reading practice
      },
    );
  }
}
