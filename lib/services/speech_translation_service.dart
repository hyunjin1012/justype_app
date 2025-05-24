import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'openai_translation_service.dart';

class SpeechTranslationService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final OpenAITranslationService _translator = OpenAITranslationService();

  bool _isListening = false;
  bool _isInitialized = false;
  String _lastRecognizedWords = '';
  String _translatedText = '';
  String _sourceLanguage = 'en';
  String _targetLanguage = 'en';
  String? _error;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastRecognizedWords => _lastRecognizedWords;
  String get translatedText => _translatedText;
  String? get error => _error;

  Function(String)? _onTranslatedTextChanged;

  void setOnTranslatedTextChanged(Function(String) callback) {
    _onTranslatedTextChanged = callback;
  }

  Future<bool> initialize() async {
    _error = null;

    try {
      final isAvailable = await _speech.initialize();

      if (!isAvailable) {
        _error =
            'Speech recognition is not available on this device. Please check your device settings and permissions.';
        return false;
      }

      final hasPermission = await _speech.hasPermission;

      if (!hasPermission) {
        _error =
            'Microphone permission is required for speech recognition. Please enable it in your device settings.';
        return false;
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      _error =
          'Failed to initialize speech recognition: $e\n\nPlease ensure:\n1. You are running on a physical device\n2. Microphone permissions are enabled\n3. Your device supports speech recognition';
      return false;
    }
  }

  void setLanguages(String source, String target) {
    _sourceLanguage = source;
    _targetLanguage = 'en';
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      throw Exception('Speech recognition not initialized');
    }

    if (_isListening) {
      await stopListening();
      return;
    }

    try {
      _isListening = true;
      notifyListeners();

      await _speech.listen(
        onResult: (result) async {
          _lastRecognizedWords = result.recognizedWords;
          notifyListeners();

          if (result.finalResult) {
            await _translateText(_lastRecognizedWords);
          }
        },
        localeId: _sourceLanguage,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      _isListening = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      notifyListeners();

      if (_lastRecognizedWords.isNotEmpty) {
        await _translateText(_lastRecognizedWords);
      }
    } catch (e) {
      _isListening = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _translateText(String text) async {
    if (text.isEmpty) return;

    try {
      if (_sourceLanguage == _targetLanguage) {
        _translatedText = text;
      } else {
        final translation = await _translator.translate(
          text,
          _sourceLanguage,
          _targetLanguage,
        );

        _translatedText = translation;
      }

      _onTranslatedTextChanged?.call(_translatedText);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
