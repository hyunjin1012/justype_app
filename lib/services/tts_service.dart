import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  // Getter for speaking state
  bool get isSpeaking => _isSpeaking;

  // Initialize TTS with default settings
  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
  }

  // Speak or stop speaking
  Future<void> speak(String text, {Function? onStateChange}) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      if (onStateChange != null) {
        onStateChange();
      }
      return;
    }

    _isSpeaking = true;
    if (onStateChange != null) {
      onStateChange();
    }

    await _flutterTts.speak(text);
  }

  // Stop speaking
  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    await _flutterTts.stop();
  }

  // Build a speak button with consistent styling
  Widget buildSpeakButton(
      BuildContext context, VoidCallback onPressed, bool isSpeaking) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
      label: Text(isSpeaking ? 'Stop' : 'Listen'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSpeaking
            ? Colors.red.shade100
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
    );
  }
}
