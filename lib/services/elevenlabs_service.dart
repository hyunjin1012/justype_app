import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class ElevenLabsService {
  static const String _apiEndpoint =
      'https://api.elevenlabs.io/v1/text-to-speech';
  late String _apiKey;
  late AudioPlayer _audioPlayer;
  bool _isSpeaking = false;
  Function? _onStateChangeCallback;
  bool _isInitialized = false;
  String? _currentAudioPath;

  // Getter for speaking state
  bool get isSpeaking => _isSpeaking;

  ElevenLabsService() {
    _initialize();
  }

  Future<void> _initialize() async {
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

      // Set up audio player listeners
      _audioPlayer.onPlayerComplete.listen((_) {
        print('Audio playback completed');
        _isSpeaking = false;
        _safeCallback();
      });

      _audioPlayer.onPlayerStateChanged.listen((state) {
        print('Audio player state changed: $state');
        if (state == PlayerState.playing) {
          _isSpeaking = true;
        } else if (state == PlayerState.stopped ||
            state == PlayerState.completed) {
          _isSpeaking = false;
        }
        _safeCallback();
      });

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

  Future<void> speak(String text, {Function? onStateChange}) async {
    if (!_isInitialized) {
      print('Error: ElevenLabs service not initialized');
      return;
    }

    if (_apiKey.isEmpty) {
      print('Error: ElevenLabs API key not configured');
      return;
    }

    _onStateChangeCallback = onStateChange;

    if (_isSpeaking) {
      await stop();
      return;
    }

    try {
      // Get the temporary directory
      final tempDir = await getTemporaryDirectory();
      final audioFile = File('${tempDir.path}/tts_audio.mp3');

      print('Making API request to ElevenLabs for text: $text');
      // Make the API request to ElevenLabs
      final response = await http.post(
        Uri.parse(
            '$_apiEndpoint/21m00Tcm4TlvDq8ikWAM'), // Using Rachel voice ID
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
          await _audioPlayer.play(DeviceFileSource(audioFile.path));
          _isSpeaking = true;
          _safeCallback();
        } catch (e) {
          print('Error playing audio: $e');
          _isSpeaking = false;
          _safeCallback();
        }
      } else {
        print('Error from ElevenLabs API: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error in ElevenLabs TTS: $e');
      print('Stack trace: $stackTrace');
      _isSpeaking = false;
      _safeCallback();
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    print('Stopping audio playback');
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      _safeCallback();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;
    print('Disposing audio player');
    try {
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
