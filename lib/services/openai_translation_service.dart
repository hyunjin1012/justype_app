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
        print('Warning: OpenAI API key not found in environment variables');
        _apiKey = '';
      } else {
        print('OpenAI API Key loaded successfully');
        _apiKey = apiKey;
      }
    } catch (e) {
      print('Error accessing environment variables: $e');
      _apiKey = '';
    }
  }

  Future<String> translate(
      String text, String sourceLanguage, String targetLanguage) async {
    print('=== OpenAI Translation Service: Starting translation ===');

    if (_apiKey.isEmpty) {
      print(
          'OpenAI Translation Service: Using Google Translator due to missing API key');
      return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
    }

    if (_quotaExceeded) {
      print(
          'OpenAI Translation Service: Using Google Translator due to quota exceeded');
      return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
    }

    try {
      print('OpenAI Translation Service: Making API request to OpenAI...');
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

      print(
          'OpenAI Translation Service: Received response with status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translation =
            data['choices'][0]['message']['content'].toString().trim();
        print(
            'OpenAI Translation Service: Successfully translated text: "$translation"');
        return translation;
      } else if (response.statusCode == 429) {
        _quotaExceeded = true;
        print(
            'OpenAI Translation Service: API Quota exceeded, switching to Google Translator');
        return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
      } else {
        print(
            'OpenAI Translation Service: API Error: ${response.statusCode} - ${response.body}');
        print('OpenAI Translation Service: Falling back to Google Translator');
        return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
      }
    } catch (e) {
      print('OpenAI Translation Service: Error translating text: $e');
      print('OpenAI Translation Service: Falling back to Google Translator');
      return _getFallbackTranslation(text, sourceLanguage, targetLanguage);
    } finally {
      print('=== OpenAI Translation Service: Finished translation attempt ===');
    }
  }

  Future<String> _getFallbackTranslation(
      String text, String sourceLanguage, String targetLanguage) async {
    try {
      print('OpenAI Translation Service: Using Google Translator as fallback');
      final translation = await _fallbackTranslator.translate(
        text,
        from: sourceLanguage,
        to: targetLanguage,
      );
      print(
          'OpenAI Translation Service: Google Translator fallback successful: "${translation.text}"');
      return translation.text;
    } catch (e) {
      print(
          'OpenAI Translation Service: Google Translator fallback failed: $e');
      // If even Google Translator fails, return the original text
      return text;
    }
  }
}
