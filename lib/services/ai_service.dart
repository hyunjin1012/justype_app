import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  static const String _apiEndpoint =
      'https://api.openai.com/v1/chat/completions';
  late String _apiKey;
  bool _quotaExceeded = false;

  AIService() {
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

  Future<Map<String, dynamic>> generateSentence() async {
    if (_apiKey.isEmpty) {
      return _getFallbackContent();
    }

    if (_quotaExceeded) {
      return _getFallbackContent(quotaExceeded: true);
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
                  'You are a helpful assistant that generates diverse and varied English sentences for typing practice. Each sentence should be between 20 and 200 characters long, grammatically correct, and meaningful. The sentences should cover different topics, styles, and complexity levels. Avoid repeating similar themes or structures. Do not include any special characters or formatting.'
            },
            {
              'role': 'user',
              'content':
                  'Generate a unique and diverse sentence for typing practice. Make it different from common typing practice sentences and avoid themes about animals, weather, or common idioms.'
            }
          ],
          'temperature': 0.9,
          'max_tokens': 100,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sentence =
            data['choices'][0]['message']['content'].toString().trim();

        // Validate the sentence length
        if (sentence.length < 20 || sentence.length > 200) {
          throw Exception(
              'Generated sentence length is not within required range');
        }

        return {
          'content': sentence,
          'bookTitle': 'AI Generated',
          'bookAuthor': 'AI',
          'currentBookId': '',
        };
      } else if (response.statusCode == 429) {
        // Handle quota exceeded error
        _quotaExceeded = true;
        return _getFallbackContent(quotaExceeded: true);
      } else {
        throw Exception('Failed to generate sentence: ${response.statusCode}');
      }
    } catch (e) {
      return _getFallbackContent();
    }
  }

  Map<String, dynamic> _getFallbackContent({bool quotaExceeded = false}) {
    final sentences = [
      "The quick brown fox jumps over the lazy dog.",
      "She sells seashells by the seashore.",
      "How much wood would a woodchuck chuck if a woodchuck could chuck wood?",
      "Peter Piper picked a peck of pickled peppers.",
      "The early bird catches the worm.",
      "A stitch in time saves nine.",
      "All that glitters is not gold.",
      "The pen is mightier than the sword.",
      "Actions speak louder than words.",
      "Better late than never."
    ];

    final random = DateTime.now().millisecondsSinceEpoch % sentences.length;
    final sentence = sentences[random];

    return {
      'content': sentence,
      'bookTitle': quotaExceeded ? 'Quota Exceeded' : 'AI Generated',
      'bookAuthor': quotaExceeded ? 'Please check your OpenAI billing' : 'AI',
      'currentBookId': '',
    };
  }
}
