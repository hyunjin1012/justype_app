import 'package:flutter/material.dart';
import '../widgets/practice_content.dart';
import '../widgets/practice_input_area.dart';
import '../services/tts_service.dart';
import '../widgets/visibility_toggle.dart';
import '../widgets/sentence_display_card.dart';
import '../services/progress_service.dart';
import '../services/sentence_manager.dart';

class ListeningPracticeScreen extends StatefulWidget {
  const ListeningPracticeScreen({super.key});

  @override
  State<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen> {
  final TtsService _ttsService = TtsService();
  final SentenceManager _sentenceManager = SentenceManager();
  bool _isTextVisible = false;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  void _speakSentence() {
    _ttsService.speak(_sentenceManager.currentSentence, onStateChange: () {
      setState(() {});
    });
  }

  void _toggleTextVisibility() {
    setState(() {
      _isTextVisible = !_isTextVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Practice'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PracticeContent(
        title: 'Listening Practice',
        heroTag: 'listening_fab',
        sentenceManager: _sentenceManager,
        // Define how to display the sentence (with speak button and visibility toggle)
        sentenceDisplay: (sentence) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ttsService.buildSpeakButton(
                      context, _speakSentence, _ttsService.isSpeaking),
                  const SizedBox(width: 16),
                  VisibilityToggle(
                    isVisible: _isTextVisible,
                    onToggle: _toggleTextVisibility,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isTextVisible) SentenceDisplayCard(sentence: sentence),
            ],
          );
        },
        // Use the shared input area widget
        inputArea: (controller, checkAnswer, feedback) => PracticeInputArea(
          controller: controller,
          onCheck: checkAnswer,
          feedback: feedback,
          labelText: 'Type what you hear',
        ),
        onRefresh: () {
          // Stop speaking if a new sentence is fetched
          _ttsService.stop();
          // Reset visibility
          setState(() {
            _isTextVisible = false;
          });
        },
      ),
    );
  }
}
