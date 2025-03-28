import 'package:flutter/material.dart';
import '../widgets/practice_content.dart';
import '../widgets/practice_input_area.dart';
import '../services/tts_service.dart';
import '../widgets/visibility_toggle.dart';
import '../widgets/sentence_display_card.dart';
import '../services/progress_service.dart';
import '../services/sentence_manager.dart';

class AudioChallengeScreen extends StatefulWidget {
  const AudioChallengeScreen({super.key});

  @override
  State<AudioChallengeScreen> createState() => _AudioChallengeScreenState();
}

class _AudioChallengeScreenState extends State<AudioChallengeScreen> {
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
      if (mounted) {
        print(
            "TTS state changed callback, isSpeaking: ${_ttsService.isSpeaking}");
        // Force a rebuild of the entire screen
        setState(() {});
      }
    });

    // Force an immediate rebuild to show the initial state change
    setState(() {});
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
        title: const Text('Audio Challenge'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: PracticeContent(
        title: 'Listening Practice',
        heroTag: 'listening_fab',
        sentenceManager: _sentenceManager,
        // Define how to display the sentence (with speak button and visibility toggle)
        sentenceDisplay: (sentence) {
          // Force rebuild when this function is called
          print(
              "Building sentence display, TTS speaking: ${_ttsService.isSpeaking}");
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
        // Use the shared input area widget with button state
        inputArea: (controller, checkAnswer, feedback, isCheckButtonEnabled) =>
            PracticeInputArea(
          controller: controller,
          onCheck: checkAnswer,
          feedback: feedback,
          labelText: 'Type what you hear',
          isCheckButtonEnabled: isCheckButtonEnabled,
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
