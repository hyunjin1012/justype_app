import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  Function? _onStateChangeCallback;
  Timer? _speechTimer;
  double _speechRate = 0.43;
  static const List<String> _preferredVoiceNames = [
    'Samantha',
    'Ava',
    'Zoe',
    'Susan',
    'Allison',
    'Evan',
  ];

  // Getter for speaking state
  bool get isSpeaking => _isSpeaking;

  // Initialize TTS with default settings
  Future<void> initialize() async {
    await _configureAudioSession();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(0.96);
    await _selectBestEnglishVoice();

    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _cancelSpeechTimer();
      _safeCallback();
    });

    // Listen to TTS status changes
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _safeCallback();
    });

    // Also listen to progress updates which might help catch completion
    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
      _safeCallback();
    });

    _flutterTts.setPauseHandler(() {
      _safeCallback();
    });

    _flutterTts.setContinueHandler(() {
      _safeCallback();
    });

    _flutterTts.setErrorHandler((error) {
      _isSpeaking = false;
      _safeCallback();
    });
  }

  Future<void> _configureAudioSession() async {
    try {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
      await _flutterTts.awaitSpeakCompletion(false);
    } catch (e) {
      debugPrint("Unable to configure TTS audio session: $e");
    }
  }

  Future<void> _selectBestEnglishVoice() async {
    try {
      final voicesResult = await _flutterTts.getVoices;
      if (voicesResult is! List) return;

      final voices = voicesResult
          .whereType<Map>()
          .map((voice) => voice.map(
                (key, value) => MapEntry(
                  key.toString(),
                  value?.toString() ?? '',
                ),
              ))
          .where((voice) {
        final locale = voice['locale']?.toLowerCase() ?? '';
        return locale == 'en-us' || locale.startsWith('en-');
      }).toList();

      if (voices.isEmpty) return;

      voices.sort(
          (first, second) => _voiceScore(second).compareTo(_voiceScore(first)));

      final selectedVoice = voices.first;
      final identifier = selectedVoice['identifier'];
      if (identifier != null && identifier.isNotEmpty) {
        await _flutterTts.setVoice({'identifier': identifier});
        return;
      }

      final name = selectedVoice['name'];
      final locale = selectedVoice['locale'];
      if (name != null &&
          name.isNotEmpty &&
          locale != null &&
          locale.isNotEmpty) {
        await _flutterTts.setVoice({'name': name, 'locale': locale});
      }
    } catch (e) {
      debugPrint("Unable to select TTS voice: $e");
    }
  }

  int _voiceScore(Map<String, String> voice) {
    final name = voice['name']?.toLowerCase() ?? '';
    final locale = voice['locale']?.toLowerCase() ?? '';
    final quality = voice['quality']?.toLowerCase() ?? '';
    final identifier = voice['identifier']?.toLowerCase() ?? '';

    var score = 0;

    if (locale == 'en-us') {
      score += 80;
    } else if (locale.startsWith('en-')) {
      score += 40;
    }

    if (quality.contains('premium')) {
      score += 80;
    } else if (quality.contains('enhanced')) {
      score += 60;
    }

    if (identifier.contains('premium')) {
      score += 40;
    } else if (identifier.contains('enhanced')) {
      score += 30;
    }

    for (var index = 0; index < _preferredVoiceNames.length; index++) {
      if (name == _preferredVoiceNames[index].toLowerCase()) {
        score += 30 - index;
        break;
      }
    }

    return score;
  }

  // Helper method to safely call the callback
  void _safeCallback() {
    if (_onStateChangeCallback != null) {
      try {
        _onStateChangeCallback!();
      } catch (e) {
        debugPrint("Error in TTS callback: $e");
        _onStateChangeCallback = null;
      }
    }
  }

  // Speak or stop speaking
  Future<void> speak(String text, {Function? onStateChange}) async {
    _onStateChangeCallback = onStateChange;

    if (_isSpeaking) {
      _cancelSpeechTimer();
      await _flutterTts.stop();
      _isSpeaking = false;
      _safeCallback();
      return;
    }

    // Explicitly set speaking state before invoking platform TTS
    _isSpeaking = true;
    _safeCallback();

    await _flutterTts.speak(_prepareSpeechText(text));

    // Start a timer as a fallback to detect when speech might be complete
    _startSpeechTimer(text);
  }

  // Start a timer to detect when speech might be complete
  void _startSpeechTimer(String text) {
    _cancelSpeechTimer(); // Cancel any existing timer

    // Estimate speech duration (roughly 1 second per 5 words at normal speed)
    final wordCount = text.split(' ').length;
    final estimatedDuration =
        Duration(milliseconds: (wordCount * 200 / _speechRate).round());

    _speechTimer = Timer(estimatedDuration, () {
      _isSpeaking = false;
      _safeCallback();
    });
  }

  String _prepareSpeechText(String text) {
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').replaceAllMapped(
          RegExp(r'([.!?])\s+'),
          (match) => '${match.group(1)}  ',
        );
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
    _cancelSpeechTimer();
    await _flutterTts.stop();
    _isSpeaking = false;
    _safeCallback();
  }

  // Clean up resources
  Future<void> dispose() async {
    _cancelSpeechTimer();
    _onStateChangeCallback = null;
    await _flutterTts.stop();
  }

  // Build a speak button with consistent styling
  Widget buildSpeakButton(
      BuildContext context, VoidCallback onPressed, bool isSpeaking) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up),
      label: Text(isSpeaking ? 'Stop' : 'Play'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSpeaking
            ? Colors.red.shade100
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
    );
  }

  // Method to set the speech rate
  void setSpeechRate(double rate) {
    _speechRate = rate;
    _flutterTts.setSpeechRate(_speechRate);
  }
}
