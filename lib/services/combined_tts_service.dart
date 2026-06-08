import 'package:flutter/material.dart';
import 'tts_service.dart';

class CombinedTtsService {
  final TtsService _ttsService = TtsService();
  bool _isSpeaking = false;
  bool _isLoading = false;
  Function? _onStateChangeCallback;
  bool _isInitialized = false;

  bool get isSpeaking => _isSpeaking;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    try {
      await _ttsService.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  void _safeCallback() {
    if (_onStateChangeCallback != null) {
      try {
        _onStateChangeCallback!();
      } catch (e) {
        _onStateChangeCallback = null;
      }
    }
  }

  Future<void> speak(String text, {Function? onStateChange}) async {
    if (!_isInitialized) {
      return;
    }

    _onStateChangeCallback = onStateChange;

    if (_isSpeaking) {
      await stop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _ttsService.speak(text, onStateChange: () {
        _isSpeaking = _ttsService.isSpeaking;
        _isLoading = false;
        _safeCallback();
      });
    } catch (e) {
      _isSpeaking = false;
      _isLoading = false;
      _safeCallback();
    }
  }

  void setState(Function() callback) {
    callback();
    _safeCallback();
  }

  Future<void> stop() async {
    if (!_isInitialized) {
      return;
    }

    try {
      await _ttsService.stop();
    } catch (e) {
      debugPrint('CombinedTtsService: Error stopping Flutter TTS: $e');
    }

    _isSpeaking = false;
    _isLoading = false;

    _safeCallback();
  }

  Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    try {
      await _ttsService.dispose();
    } catch (e) {
      debugPrint('CombinedTtsService: Error disposing Flutter TTS: $e');
    }
  }

  Widget buildSpeakButton(
      BuildContext context, VoidCallback onPressed, bool isSpeaking) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(_isLoading
          ? Icons.hourglass_empty
          : (isSpeaking ? Icons.stop : Icons.volume_up)),
      label: Text(_isLoading ? 'Loading...' : (isSpeaking ? 'Stop' : 'Play')),
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
