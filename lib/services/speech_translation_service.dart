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
  String? _status;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastRecognizedWords => _lastRecognizedWords;
  String get translatedText => _translatedText;
  String? get error => _error;

  Function(String)? _onTranslatedTextChanged;

  void setOnTranslatedTextChanged(Function(String) callback) {
    print('SpeechTranslationService: Setting translation callback');
    _onTranslatedTextChanged = callback;
  }

  Future<bool> initialize() async {
    print('SpeechTranslationService: Starting initialization');
    _status = 'Initializing...';
    _error = null;

    try {
      print(
          'SpeechTranslationService: Checking speech recognition availability');
      final isAvailable = await _speech.initialize();
      print(
          'SpeechTranslationService: Speech recognition available: $isAvailable');

      if (!isAvailable) {
        _status = 'Speech recognition not available';
        _error =
            'Speech recognition is not available on this device. Please check your device settings and permissions.';
        return false;
      }

      print('SpeechTranslationService: Checking permissions');
      final hasPermission = await _speech.hasPermission;
      print('SpeechTranslationService: Has permission: $hasPermission');

      if (!hasPermission) {
        _status = 'Permission required';
        _error =
            'Microphone permission is required for speech recognition. Please enable it in your device settings.';
        return false;
      }

      _status = 'Initialized';
      _isInitialized = true;
      return true;
    } catch (e, stackTrace) {
      print('SpeechTranslationService: Error during initialization: $e');
      print('SpeechTranslationService: Stack trace: $stackTrace');
      _status = 'Error';
      _error =
          'Failed to initialize speech recognition: $e\n\nPlease ensure:\n1. You are running on a physical device\n2. Microphone permissions are enabled\n3. Your device supports speech recognition';
      return false;
    }
  }

  void setLanguages(String source, String target) {
    print(
        'SpeechTranslationService: Setting languages from: $source to: $target');
    _sourceLanguage = source;
    _targetLanguage = target;
    notifyListeners();
  }

  Future<void> startListening() async {
    print('SpeechTranslationService: Starting listening');
    if (!_isInitialized) {
      print(
          'SpeechTranslationService: Not initialized, cannot start listening');
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
      print('SpeechTranslationService: Successfully started listening');
    } catch (e) {
      print('SpeechTranslationService: Error starting listening: $e');
      _isListening = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> stopListening() async {
    print('SpeechTranslationService: Stopping listening');
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      print('SpeechTranslationService: Successfully stopped listening');

      if (_lastRecognizedWords.isNotEmpty) {
        await _translateText(_lastRecognizedWords);
      }
    } catch (e) {
      print('SpeechTranslationService: Error stopping listening: $e');
      _isListening = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _translateText(String text) async {
    print('SpeechTranslationService: Translating text: $text');
    if (text.isEmpty) return;

    try {
      if (_sourceLanguage == _targetLanguage) {
        print(
            'SpeechTranslationService: Source and target languages are the same, skipping translation');
        _translatedText = text;
      } else {
        final translation = await _translator.translate(
          text,
          _sourceLanguage,
          _targetLanguage,
        );
        print('SpeechTranslationService: Translation successful: $translation');
        _translatedText = translation;
      }

      _onTranslatedTextChanged?.call(_translatedText);
      notifyListeners();
    } catch (e) {
      print('SpeechTranslationService: Error translating text: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    print('SpeechTranslationService: Disposing service');
    _speech.stop();
    super.dispose();
  }
}
