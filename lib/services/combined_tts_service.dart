import 'package:flutter/material.dart';
import 'elevenlabs_service.dart';
import 'tts_service.dart';

class CombinedTtsService {
  final ElevenLabsService _elevenLabsService = ElevenLabsService();
  final TtsService _ttsService = TtsService();
  bool _isSpeaking = false;
  bool _isLoading = false;
  Function? _onStateChangeCallback;
  bool _isInitialized = false;
  bool _isUsingElevenLabs = true;

  bool get isSpeaking => _isSpeaking;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    print('CombinedTtsService: Initializing...');
    try {
      await _elevenLabsService.initialize();
      await _ttsService.initialize();
      _isInitialized = true;
      print('CombinedTtsService: Initialization complete');
    } catch (e) {
      print('CombinedTtsService: Error initializing: $e');
      _isInitialized = false;
    }
  }

  void _safeCallback() {
    print(
        'CombinedTtsService: Safe callback called, isSpeaking: $_isSpeaking, isLoading: $_isLoading');
    if (_onStateChangeCallback != null) {
      try {
        _onStateChangeCallback!();
      } catch (e) {
        print("CombinedTtsService: Error in callback: $e");
        _onStateChangeCallback = null;
      }
    }
  }

  Future<void> speak(String text, {Function? onStateChange}) async {
    print('CombinedTtsService: Speak called with text length: ${text.length}');
    print(
        'CombinedTtsService: Current state - isSpeaking: $_isSpeaking, isLoading: $_isLoading, isUsingElevenLabs: $_isUsingElevenLabs');

    if (!_isInitialized) {
      print('CombinedTtsService: Error - not initialized');
      return;
    }

    _onStateChangeCallback = onStateChange;

    if (_isSpeaking) {
      print('CombinedTtsService: Already speaking, stopping current speech');
      await stop();
      return;
    }

    setState(() {
      _isLoading = true;
    });
    print('CombinedTtsService: Set loading state to true');

    try {
      // Try ElevenLabs first
      print('CombinedTtsService: Attempting to use ElevenLabs');
      _isUsingElevenLabs = true;
      final success = await _elevenLabsService.speak(text, onStateChange: () {
        print(
            'CombinedTtsService: ElevenLabs state change - isSpeaking: ${_elevenLabsService.isSpeaking}');
        if (_isUsingElevenLabs) {
          _isSpeaking = _elevenLabsService.isSpeaking;
          _isLoading = false;
          _safeCallback();
        }
      });

      // If ElevenLabs failed, fall back to Flutter TTS
      if (!success) {
        print(
            'CombinedTtsService: ElevenLabs failed, falling back to Flutter TTS');
        _isUsingElevenLabs = false;
        await _ttsService.speak(text, onStateChange: () {
          print(
              'CombinedTtsService: Flutter TTS state change - isSpeaking: ${_ttsService.isSpeaking}');
          if (!_isUsingElevenLabs) {
            _isSpeaking = _ttsService.isSpeaking;
            _isLoading = false;
            _safeCallback();
          }
        });
      } else {
        print('CombinedTtsService: ElevenLabs started successfully');
      }
    } catch (e) {
      print(
          'CombinedTtsService: Error in ElevenLabs, falling back to Flutter TTS: $e');
      // Fall back to Flutter TTS
      _isUsingElevenLabs = false;
      await _ttsService.speak(text, onStateChange: () {
        print(
            'CombinedTtsService: Flutter TTS state change (error fallback) - isSpeaking: ${_ttsService.isSpeaking}');
        if (!_isUsingElevenLabs) {
          _isSpeaking = _ttsService.isSpeaking;
          _isLoading = false;
          _safeCallback();
        }
      });
    }
  }

  void setState(Function() callback) {
    print('CombinedTtsService: setState called');
    callback();
    _safeCallback();
  }

  Future<void> stop() async {
    print('CombinedTtsService: Stop called');
    if (!_isInitialized) {
      print('CombinedTtsService: Stop called but not initialized');
      return;
    }

    // Stop both services to ensure clean state
    try {
      print('CombinedTtsService: Stopping ElevenLabs');
      await _elevenLabsService.stop();
    } catch (e) {
      print('CombinedTtsService: Error stopping ElevenLabs: $e');
    }

    try {
      print('CombinedTtsService: Stopping Flutter TTS');
      await _ttsService.stop();
    } catch (e) {
      print('CombinedTtsService: Error stopping Flutter TTS: $e');
    }

    _isSpeaking = false;
    _isLoading = false;
    _isUsingElevenLabs = true;
    print('CombinedTtsService: Reset all states after stop');
    _safeCallback();
  }

  Future<void> dispose() async {
    print('CombinedTtsService: Dispose called');
    if (!_isInitialized) {
      print('CombinedTtsService: Dispose called but not initialized');
      return;
    }

    try {
      print('CombinedTtsService: Disposing ElevenLabs');
      await _elevenLabsService.dispose();
    } catch (e) {
      print('CombinedTtsService: Error disposing ElevenLabs: $e');
    }

    try {
      print('CombinedTtsService: Disposing Flutter TTS');
      await _ttsService.dispose();
    } catch (e) {
      print('CombinedTtsService: Error disposing Flutter TTS: $e');
    }
  }

  Widget buildSpeakButton(
      BuildContext context, VoidCallback onPressed, bool isSpeaking) {
    print(
        'CombinedTtsService: Building button - isSpeaking: $isSpeaking, isLoading: $_isLoading');
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(_isLoading
          ? Icons.hourglass_empty
          : (isSpeaking ? Icons.stop : Icons.volume_up)),
      label: Text(_isLoading ? 'Loading...' : (isSpeaking ? 'Stop' : 'Listen')),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSpeaking ? Colors.red.shade100 : colorScheme.primary,
        foregroundColor:
            isSpeaking ? Colors.red.shade900 : colorScheme.onPrimary,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade600,
      ),
    );
  }
}
