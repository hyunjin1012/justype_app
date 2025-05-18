import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ElevenLabsService {
  static const String _apiEndpoint =
      'https://api.elevenlabs.io/v1/text-to-speech';
  late String _apiKey;
  late AudioPlayer _audioPlayer;
  bool _isSpeaking = false;
  Function? _onStateChangeCallback;
  bool _isInitialized = false;
  String? _currentAudioPath;
  bool _hasCompleted = false;
  StreamSubscription? _completionSubscription;
  StreamSubscription? _stateSubscription;

  // Getter for speaking state
  bool get isSpeaking => _isSpeaking;

  ElevenLabsService() {
    initialize();
  }

  Future<void> initialize() async {
    try {
      final apiKey = dotenv.env['ELEVENLABS_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('Warning: ElevenLabs API key not found in environment variables');
        _apiKey = '';
      } else {
        print('ElevenLabs API Key loaded successfully');
        _apiKey = apiKey;
      }

      // Initialize audio player
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing ElevenLabs service: $e');
      _isInitialized = false;
    }
  }

  // Helper method to safely call the callback
  void _safeCallback() {
    if (_onStateChangeCallback != null) {
      try {
        _onStateChangeCallback!();
      } catch (e) {
        print("Error in ElevenLabs callback: $e");
        _onStateChangeCallback = null;
      }
    }
  }

  Future<bool> speak(String text, {Function? onStateChange}) async {
    if (!_isInitialized) {
      print('Error: ElevenLabs service not initialized');
      return false;
    }

    if (_apiKey.isEmpty) {
      print('Error: ElevenLabs API key not configured');
      return false;
    }

    _onStateChangeCallback = onStateChange;
    _hasCompleted = false;

    if (_isSpeaking) {
      await stop();
      return true;
    }

    try {
      // Cancel any existing subscriptions
      await _completionSubscription?.cancel();
      await _stateSubscription?.cancel();

      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/tts_audio.mp3');

      print('Making API request to ElevenLabs for text: $text');
      // Make the API request to ElevenLabs
      final response = await http.post(
        Uri.parse('$_apiEndpoint/21m00Tcm4TlvDq8ikWAM'),
        headers: {
          'Accept': 'audio/mpeg',
          'xi-api-key': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
        }),
      );

      if (response.statusCode == 200) {
        print(
            'Received audio data from ElevenLabs, size: ${response.bodyBytes.length} bytes');
        // Save the audio file
        await audioFile.writeAsBytes(response.bodyBytes);
        _currentAudioPath = audioFile.path;

        print('Playing audio from file: ${audioFile.path}');
        // Play the audio
        try {
          // Set up completion handler before playing
          _completionSubscription = _audioPlayer.onPlayerComplete.listen((_) {
            if (!_hasCompleted) {
              print('ElevenLabs: Audio playback completed');
              _hasCompleted = true;
              _isSpeaking = false;
              _safeCallback();
            }
          });

          _stateSubscription =
              _audioPlayer.onPlayerStateChanged.listen((state) {
            print('ElevenLabs: Audio player state changed: $state');
            if (state == PlayerState.playing) {
              _isSpeaking = true;
            } else if (state == PlayerState.stopped ||
                state == PlayerState.completed) {
              if (!_hasCompleted) {
                _isSpeaking = false;
                _hasCompleted = true;
              }
            }
            _safeCallback();
          });

          // Start playback
          await _audioPlayer.play(DeviceFileSource(audioFile.path));
          _isSpeaking = true;
          _safeCallback();
          return true;
        } catch (e) {
          print('Error playing audio: $e');
          _isSpeaking = false;
          _safeCallback();
          return false;
        }
      } else {
        print('Error from ElevenLabs API: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('Error in ElevenLabs TTS: $e');
      print('Stack trace: $stackTrace');
      _isSpeaking = false;
      _safeCallback();
      return false;
    }
  }

  List<String> _splitTextIntoChunks(String text, int maxChunkSize) {
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final chunks = <String>[];
    var currentChunk = '';

    for (final sentence in sentences) {
      final trimmedSentence = sentence.trim();
      if (currentChunk.isEmpty) {
        currentChunk = trimmedSentence;
      } else if (currentChunk.length + trimmedSentence.length + 2 <=
          maxChunkSize) {
        currentChunk += '. $trimmedSentence';
      } else {
        chunks.add(currentChunk);
        currentChunk = trimmedSentence;
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }

    return chunks;
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    print('ElevenLabs: Stopping audio playback');
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      _hasCompleted = false;
      _safeCallback();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;
    print('ElevenLabs: Disposing audio player');
    try {
      await _completionSubscription?.cancel();
      await _stateSubscription?.cancel();
      await _audioPlayer.dispose();
      // Clean up the audio file if it exists
      if (_currentAudioPath != null) {
        final file = File(_currentAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error during disposal: $e');
    }
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
