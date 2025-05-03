import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  Function? _onStateChangeCallback;
  Timer? _speechTimer;
  double _speechRate = 0.5; // Default is already 0.5 for normal speed

  // Getter for speaking state
  bool get isSpeaking => _isSpeaking;

  // Initialize TTS with default settings
  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      print("TTS completed - completion handler");
      _isSpeaking = false;
      _cancelSpeechTimer();
      _safeCallback();
    });

    // Listen to TTS status changes
    _flutterTts.setStartHandler(() {
      print("TTS started - start handler");
      _isSpeaking = true;
      _safeCallback();
    });

    // Also listen to progress updates which might help catch completion
    _flutterTts.setCancelHandler(() {
      print("TTS cancelled - cancel handler");
      _isSpeaking = false;
      _safeCallback();
    });

    _flutterTts.setPauseHandler(() {
      print("TTS paused - pause handler");
      _safeCallback();
    });

    _flutterTts.setContinueHandler(() {
      print("TTS continued - continue handler");
      _safeCallback();
    });

    _flutterTts.setErrorHandler((error) {
      print("TTS error: $error - error handler");
      _isSpeaking = false;
      _safeCallback();
    });
  }

  // Helper method to safely call the callback
  void _safeCallback() {
    if (_onStateChangeCallback != null) {
      try {
        _onStateChangeCallback!();
      } catch (e) {
        print("Error in TTS callback: $e");
        _onStateChangeCallback = null;
      }
    }
  }

  // Speak or stop speaking
  Future<void> speak(String text, {Function? onStateChange}) async {
    print("TTS speak called, current state: $_isSpeaking");
    _onStateChangeCallback = onStateChange;

    if (_isSpeaking) {
      print("Stopping TTS");
      _cancelSpeechTimer();
      await _flutterTts.stop();
      _isSpeaking = false;
      _safeCallback();
      return;
    }

    print("Starting TTS");
    // Explicitly set speaking state before calling the API
    _isSpeaking = true;
    _safeCallback();

    await _flutterTts.speak(text);

    // Start a timer as a fallback to detect when speech might be complete
    _startSpeechTimer(text, onStateChange);
  }

  // Start a timer to detect when speech might be complete
  void _startSpeechTimer(String text, Function? onStateChange) {
    _cancelSpeechTimer(); // Cancel any existing timer

    // Estimate speech duration (roughly 1 second per 5 words at normal speed)
    final wordCount = text.split(' ').length;
    final estimatedDuration =
        Duration(milliseconds: (wordCount * 200 / _speechRate).round());

    _speechTimer = Timer(estimatedDuration, () {
      print("Speech timer completed");
      _isSpeaking = false;
      _safeCallback();
    });
  }

  // Cancel the speech timer
  void _cancelSpeechTimer() {
    if (_speechTimer != null) {
      _speechTimer!.cancel();
      _speechTimer = null;
    }
  }

  // Stop speaking
  Future<void> stop() async {
    print("TTS stop called");
    _cancelSpeechTimer();
    await _flutterTts.stop();
    _isSpeaking = false;
    _safeCallback();
  }

  // Clean up resources
  Future<void> dispose() async {
    print("TTS dispose called");
    _cancelSpeechTimer();
    _onStateChangeCallback = null;
    await _flutterTts.stop();
  }

  // Build a speak button with consistent styling
  Widget buildSpeakButton(
      BuildContext context, VoidCallback onPressed, bool isSpeaking) {
    print("Building button with isSpeaking: $isSpeaking");
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

  // Method to set the speech rate
  void setSpeechRate(double rate) {
    _speechRate = rate;
    _flutterTts.setSpeechRate(_speechRate);
  }
}
