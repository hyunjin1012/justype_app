import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  Function? _onStateChangeCallback;
  Timer? _speechTimer;

  // Getter for speaking state
  bool get isSpeaking => _isSpeaking;

  // Initialize TTS with default settings
  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      print("TTS completed - completion handler");
      _isSpeaking = false;
      _cancelSpeechTimer();
      if (_onStateChangeCallback != null) {
        _onStateChangeCallback!();
      }
    });

    // Listen to TTS status changes
    _flutterTts.setStartHandler(() {
      print("TTS started - start handler");
      _isSpeaking = true;
      if (_onStateChangeCallback != null) {
        _onStateChangeCallback!();
      }
    });

    // Also listen to progress updates which might help catch completion
    _flutterTts.setCancelHandler(() {
      print("TTS cancelled - cancel handler");
      _isSpeaking = false;
      if (_onStateChangeCallback != null) {
        _onStateChangeCallback!();
      }
    });

    _flutterTts.setPauseHandler(() {
      print("TTS paused - pause handler");
      if (_onStateChangeCallback != null) {
        _onStateChangeCallback!();
      }
    });

    _flutterTts.setContinueHandler(() {
      print("TTS continued - continue handler");
      if (_onStateChangeCallback != null) {
        _onStateChangeCallback!();
      }
    });

    _flutterTts.setErrorHandler((error) {
      print("TTS error: $error - error handler");
      _isSpeaking = false;
      if (_onStateChangeCallback != null) {
        _onStateChangeCallback!();
      }
    });
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
      if (onStateChange != null) {
        onStateChange();
      }
      return;
    }

    print("Starting TTS");
    // Explicitly set speaking state before calling the API
    _isSpeaking = true;
    if (onStateChange != null) {
      onStateChange();
    }

    await _flutterTts.speak(text);

    // Start a timer as a fallback to detect when speech might be complete
    _startSpeechTimer(text, onStateChange);
  }

  // Start a timer based on text length to detect when speech might be complete
  void _startSpeechTimer(String text, Function? onStateChange) {
    _cancelSpeechTimer();

    // Estimate speech duration based on text length and speaking rate
    // Assuming average speaking rate of 2-3 words per second at 0.5 speed
    int wordCount = text.split(' ').length;
    int estimatedDurationInSeconds = (wordCount / 1.5).ceil() + 2; // Add buffer

    print("Starting speech timer for $estimatedDurationInSeconds seconds");
    _speechTimer = Timer(Duration(seconds: estimatedDurationInSeconds), () {
      if (_isSpeaking) {
        print("Speech timer expired - assuming speech is complete");
        _isSpeaking = false;
        if (onStateChange != null) {
          onStateChange();
        }
      }
    });
  }

  void _cancelSpeechTimer() {
    if (_speechTimer != null && _speechTimer!.isActive) {
      _speechTimer!.cancel();
      _speechTimer = null;
    }
  }

  // Stop speaking
  Future<void> stop() async {
    _cancelSpeechTimer();
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
      if (_onStateChangeCallback != null) {
        _onStateChangeCallback!();
      }
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    _cancelSpeechTimer();
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
}
