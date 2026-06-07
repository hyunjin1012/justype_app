import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('library corpus has unique ids and enough usable prompts', () {
    final books = [
      ..._loadJsonList('assets/corpus/books.json'),
      ..._loadJsonList('assets/corpus/original_packs.json'),
    ];
    final ids = <int>{};
    final prompts = <String>[];

    for (final book in books) {
      expect(book['id'], isA<int>());
      expect(ids.add(book['id'] as int), isTrue);
      expect((book['title'] as String).trim(), isNotEmpty);
      expect((book['author'] as String).trim(), isNotEmpty);
      expect(book['subjects'], isA<List<dynamic>>());
      expect((book['subjects'] as List<dynamic>), isNotEmpty);
      expect((book['content'] as String).trim(), isNotEmpty);

      prompts.addAll(_extractSentences(book['content'] as String));
    }

    expect(books.length, greaterThanOrEqualTo(60));
    expect(prompts.length, greaterThanOrEqualTo(1000));
    expect(prompts.toSet().length, prompts.length);
  });

  test('phrase packs have enough prompts and required fields', () {
    final packs = _loadJsonMap('assets/translations/phrase_packs.json');
    var totalPrompts = 0;

    for (final entry in packs.entries) {
      final language = entry.key;
      final prompts = entry.value as List<dynamic>;
      expect(prompts.length, greaterThanOrEqualTo(30));
      totalPrompts += prompts.length;

      for (final prompt in prompts) {
        final data = prompt as Map<String, dynamic>;
        expect((data['source'] as String).trim(), isNotEmpty);
        expect((data['target'] as String).trim(), isNotEmpty);
        if (['ja', 'zh', 'ru', 'ar', 'ko'].contains(language)) {
          expect((data['romanization'] as String?)?.trim(), isNotEmpty);
        }
      }
    }

    expect(totalPrompts, greaterThanOrEqualTo(300));
  });
}

List<dynamic> _loadJsonList(String path) {
  return json.decode(File(path).readAsStringSync()) as List<dynamic>;
}

Map<String, dynamic> _loadJsonMap(String path) {
  return json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

List<String> _extractSentences(String content) {
  var preprocessed = content;
  final abbreviations = [
    'Mr.',
    'Mrs.',
    'Ms.',
    'Dr.',
    'Prof.',
    'St.',
    'Jr.',
    'Sr.',
  ];

  for (final abbreviation in abbreviations) {
    preprocessed = preprocessed.replaceAllMapped(
      RegExp('$abbreviation (\\w)'),
      (match) =>
          '${abbreviation.substring(0, abbreviation.length - 1)}###PERIOD### ${match.group(1)}',
    );
  }

  preprocessed = preprocessed.replaceAllMapped(
    RegExp(r'([A-Z])\. ([A-Z])'),
    (match) => '${match.group(1)}###PERIOD### ${match.group(2)}',
  );

  return preprocessed
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((sentence) => sentence
          .replaceAll('###PERIOD###', '.')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .replaceFirst(RegExp(r'^[A-Za-z][A-Za-z ]{0,32}:\s*'), ''))
      .where((sentence) {
    if (sentence.length < 20 || sentence.length > 200) {
      return false;
    }

    return sentence.endsWith('.') ||
        sentence.endsWith('!') ||
        sentence.endsWith('?');
  }).toList();
}
