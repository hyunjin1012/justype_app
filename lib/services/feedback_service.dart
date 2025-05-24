import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class FeedbackService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  // Sound effect paths
  final String _correctSoundPath = 'sounds/correct.mp3';
  final String _wrongSoundPath = 'sounds/wrong.mp3';
  final String _loadSoundPath = 'sounds/load.mp3';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Preload sound effects
      await _audioPlayer.setSource(AssetSource(_correctSoundPath));
      await _audioPlayer.setSource(AssetSource(_wrongSoundPath));
      await _audioPlayer.setSource(AssetSource(_loadSoundPath));
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing feedback service: $e');
    }
  }

  Future<void> playCorrectSound() async {
    if (!_isInitialized) await initialize();
    try {
      await _audioPlayer.play(AssetSource(_correctSoundPath));
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Error playing correct sound: $e');
    }
  }

  Future<void> playWrongSound() async {
    if (!_isInitialized) await initialize();
    try {
      await _audioPlayer.play(AssetSource(_wrongSoundPath));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Error playing wrong sound: $e');
    }
  }

  Future<void> playLoadSound() async {
    if (!_isInitialized) await initialize();
    try {
      await _audioPlayer.play(AssetSource(_loadSoundPath));
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error playing load sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
