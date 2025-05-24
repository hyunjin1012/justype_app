import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:translator/translator.dart';

class OpenAITranslationService {
  static const String _apiEndpoint =
      'https://api.openai.com/v1/chat/completions';
  late String _apiKey;
  bool _quotaExceeded = false;
  final GoogleTranslator _fallbackTranslator = GoogleTranslator();

  OpenAITranslationService() {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        _apiKey = '';
      } else {
        _apiKey = apiKey;
      }
    } catch (e) {
      _apiKey = '';
    }
  }

  Future<String> translate(
      String text, String sourceLanguage, String targetLanguage) async {
    if (_apiKey.isEmpty) {
      return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
    }

    if (_quotaExceeded) {
      return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional translator. Translate the given text accurately while preserving its meaning, tone, and context. Provide only the translated text without any explanations or additional content.'
            },
            {
              'role': 'user',
              'content':
                  'Translate the following text from $sourceLanguage to $targetLanguage: $text'
            }
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translation =
            data['choices'][0]['message']['content'].toString().trim();

        return translation;
      } else if (response.statusCode == 429) {
        _quotaExceeded = true;

        return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
      } else {
        return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
      }
    } catch (e) {
      return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
    } finally {}
  }

  Future<String> _getFallbackTranslation(
      String text, String sourceLanguage, String targetLanguage) async {
    try {
      final translation = await _fallbackTranslator.translate(
        text,
        from: sourceLanguage,
        to: targetLanguage,
      );

      return translation.text;
    } catch (e) {
      // If even Google Translator fails, return the original text
      return text;
    }
  }
}
