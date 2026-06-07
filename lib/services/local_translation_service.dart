import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class TranslationPrompt {
  final String sourceLanguage;
  final String targetLanguage;
  final String sourceText;
  final String targetText;
  final String scenario;

  const TranslationPrompt({
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.sourceText,
    required this.targetText,
    required this.scenario,
  });
}

class LocalTranslationService {
  static const String _assetPath = 'assets/translations/phrase_packs.json';

  final Random _random = Random();
  Map<String, List<TranslationPrompt>>? _phrasePacks;

  Future<TranslationPrompt> getRandomPrompt(
    String sourceLanguage,
    String targetLanguage,
    String scenario,
  ) async {
    final packs = await _loadPhrasePacks();
    final prompts = packs[sourceLanguage] ?? packs['en'] ?? [];
    final scenarioPrompts = scenario == 'All'
        ? prompts
        : prompts.where((prompt) => prompt.scenario == scenario).toList();
    final availablePrompts =
        scenarioPrompts.isEmpty ? prompts : scenarioPrompts;

    if (availablePrompts.isEmpty) {
      return TranslationPrompt(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        sourceText: 'Learning improves with small daily sessions.',
        targetText: 'Learning improves with small daily sessions.',
        scenario: 'Core',
      );
    }

    return availablePrompts[_random.nextInt(availablePrompts.length)];
  }

  Future<List<String>> getScenarios(String sourceLanguage) async {
    final packs = await _loadPhrasePacks();
    final prompts = packs[sourceLanguage] ?? const <TranslationPrompt>[];
    final scenarios = prompts.map((prompt) => prompt.scenario).toSet().toList()
      ..sort();

    return ['All', ...scenarios];
  }

  Future<String> translate(
    String text,
    String sourceLanguage,
    String targetLanguage,
  ) async {
    if (sourceLanguage == targetLanguage) {
      return text;
    }

    final packs = await _loadPhrasePacks();
    final prompts = packs[sourceLanguage] ?? const <TranslationPrompt>[];
    final normalizedInput = _normalize(text);

    for (final prompt in prompts) {
      if (_normalize(prompt.sourceText) == normalizedInput) {
        return prompt.targetText;
      }
    }

    return text;
  }

  Future<Map<String, List<TranslationPrompt>>> _loadPhrasePacks() async {
    if (_phrasePacks != null) {
      return _phrasePacks!;
    }

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;

    _phrasePacks = decoded.map((language, entries) {
      final prompts = (entries as List<dynamic>).map((entry) {
        final data = entry as Map<String, dynamic>;
        return TranslationPrompt(
          sourceLanguage: language,
          targetLanguage: 'en',
          sourceText: data['source'] as String,
          targetText: data['target'] as String,
          scenario: data['scenario'] as String? ?? 'Core',
        );
      }).toList();

      return MapEntry(language, prompts);
    });

    return _phrasePacks!;
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
