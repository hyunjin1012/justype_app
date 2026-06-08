import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_service.dart';

class SavedPrompt {
  final String id;
  final String prompt;
  final String sourceLabel;
  final int savedAt;

  const SavedPrompt({
    required this.id,
    required this.prompt,
    required this.sourceLabel,
    required this.savedAt,
  });

  DateTime get savedAtDate => DateTime.fromMillisecondsSinceEpoch(savedAt);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prompt': prompt,
      'sourceLabel': sourceLabel,
      'savedAt': savedAt,
    };
  }

  factory SavedPrompt.fromJson(Map<String, dynamic> json) {
    final prompt = json['prompt'] as String? ?? '';

    return SavedPrompt(
      id: json['id'] as String? ?? SavedPromptService.promptIdFor(prompt),
      prompt: prompt,
      sourceLabel: json['sourceLabel'] as String? ?? 'Practice',
      savedAt: json['savedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class SavedPromptService extends ChangeNotifier {
  static const _savedPromptsKey = 'savedPrompts';

  bool _isLoaded = false;
  List<SavedPrompt> _savedPrompts = [];

  List<SavedPrompt> get savedPrompts => List.unmodifiable(_savedPrompts);
  int get savedPromptCount => _savedPrompts.length;
  bool get isLoaded => _isLoaded;

  static String promptIdFor(String prompt) {
    final trimmedPrompt = prompt.trim();
    final normalizedKey = ProgressService.normalizePromptKey(trimmedPrompt);
    if (normalizedKey.isNotEmpty) {
      return normalizedKey;
    }

    return base64Url.encode(utf8.encode(trimmedPrompt.toLowerCase()));
  }

  Future<void> loadSavedPrompts() async {
    if (_isLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    final encodedPrompts = prefs.getStringList(_savedPromptsKey) ?? [];
    final loadedPrompts = <SavedPrompt>[];
    final seenIds = <String>{};

    for (final encodedPrompt in encodedPrompts) {
      try {
        final decoded = json.decode(encodedPrompt) as Map<String, dynamic>;
        final savedPrompt = SavedPrompt.fromJson(decoded);
        if (savedPrompt.prompt.trim().isEmpty ||
            seenIds.contains(savedPrompt.id)) {
          continue;
        }

        loadedPrompts.add(savedPrompt);
        seenIds.add(savedPrompt.id);
      } catch (_) {
        // Ignore malformed saved prompt data so one bad entry cannot break launch.
      }
    }

    loadedPrompts.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    _savedPrompts = loadedPrompts;
    _isLoaded = true;
    notifyListeners();
  }

  bool isSaved(String prompt) {
    final id = promptIdFor(prompt);
    return _savedPrompts.any((savedPrompt) => savedPrompt.id == id);
  }

  SavedPrompt? promptById(String id) {
    for (final savedPrompt in _savedPrompts) {
      if (savedPrompt.id == id) {
        return savedPrompt;
      }
    }

    return null;
  }

  Future<bool> togglePrompt({
    required String prompt,
    required String sourceLabel,
  }) async {
    await loadSavedPrompts();

    if (isSaved(prompt)) {
      await removePrompt(prompt);
      return false;
    }

    await savePrompt(prompt: prompt, sourceLabel: sourceLabel);
    return true;
  }

  Future<void> savePrompt({
    required String prompt,
    required String sourceLabel,
  }) async {
    await loadSavedPrompts();

    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) return;

    final id = promptIdFor(trimmedPrompt);
    if (_savedPrompts.any((savedPrompt) => savedPrompt.id == id)) {
      return;
    }

    _savedPrompts = [
      SavedPrompt(
        id: id,
        prompt: trimmedPrompt,
        sourceLabel:
            sourceLabel.trim().isEmpty ? 'Practice' : sourceLabel.trim(),
        savedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      ..._savedPrompts,
    ];

    await _persist();
  }

  Future<void> removePrompt(String prompt) async {
    await loadSavedPrompts();

    await removePromptById(promptIdFor(prompt));
  }

  Future<void> removePromptById(String id) async {
    await loadSavedPrompts();

    final previousLength = _savedPrompts.length;
    _savedPrompts = _savedPrompts
        .where((savedPrompt) => savedPrompt.id != id)
        .toList(growable: false);

    if (_savedPrompts.length != previousLength) {
      await _persist();
    }
  }

  Future<void> clearSavedPrompts() async {
    _savedPrompts = [];
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _savedPromptsKey,
      _savedPrompts
          .map((savedPrompt) => json.encode(savedPrompt.toJson()))
          .toList(),
    );
    notifyListeners();
  }
}
