import 'package:flutter_test/flutter_test.dart';
import 'package:justype/services/local_translation_service.dart';
import 'package:justype/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('translation prompt keys keep languages separate', () {
    const spanishPrompt = TranslationPrompt(
      sourceLanguage: 'es',
      targetLanguage: 'en',
      sourceText:
          'Necesito indicaciones para llegar a la farmacia más cercana.',
      targetText: 'I need directions to the nearest pharmacy.',
      scenario: 'Travel',
    );
    const japanesePrompt = TranslationPrompt(
      sourceLanguage: 'ja',
      targetLanguage: 'en',
      sourceText: '一番近い薬局への道を教えてください。',
      sourceRomanization:
          'Ichiban chikai yakkyoku e no michi o oshiete kudasai.',
      targetText: 'I need directions to the nearest pharmacy.',
      scenario: 'Travel',
    );

    expect(
      LocalTranslationService.practiceKeyForPrompt(spanishPrompt),
      isNot(LocalTranslationService.practiceKeyForPrompt(japanesePrompt)),
    );
  });

  test('progress can track a hidden practice key without exposing it',
      () async {
    SharedPreferences.setMockInitialValues({});
    final progressService = ProgressService();
    await progressService.resetAllProgress();

    const visiblePrompt = 'I need directions to the nearest pharmacy.';
    const hiddenPromptKey =
        'translation | es | en | Travel | Necesito indicaciones para llegar a la farmacia más cercana. | I need directions to the nearest pharmacy.';

    await progressService.completeExercise(
      practiceType: 'translation',
      prompt: visiblePrompt,
      promptKey: hiddenPromptKey,
      wordCount: 7,
      elapsedSeconds: 5,
    );

    expect(progressService.hasPracticedPrompt(hiddenPromptKey), isTrue);
    expect(progressService.hasPracticedPrompt(visiblePrompt), isFalse);
    expect(progressService.getSessionHistory(limit: 1).single.prompt,
        visiblePrompt);
  });
}
