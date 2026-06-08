import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:justype/services/saved_prompt_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves, dedupes, removes, and reloads prompts', () async {
    final service = SavedPromptService();
    await service.loadSavedPrompts();

    await service.savePrompt(
      prompt: 'Bring a sweater because the restaurant is always cold.',
      sourceLabel: 'Library: Phone Call',
    );
    await service.savePrompt(
      prompt: 'bring a sweater because the restaurant is always cold',
      sourceLabel: 'Text Challenge',
    );

    expect(service.savedPromptCount, 1);
    expect(
      service.isSaved('Bring a sweater because the restaurant is always cold.'),
      isTrue,
    );
    expect(service.savedPrompts.first.sourceLabel, 'Library: Phone Call');

    final reloadedService = SavedPromptService();
    await reloadedService.loadSavedPrompts();

    expect(reloadedService.savedPromptCount, 1);
    expect(reloadedService.savedPrompts.first.prompt,
        'Bring a sweater because the restaurant is always cold.');

    await reloadedService.removePrompt(
      'Bring a sweater because the restaurant is always cold.',
    );

    expect(reloadedService.savedPromptCount, 0);
  });

  test('toggle returns the new saved state', () async {
    final service = SavedPromptService();
    await service.loadSavedPrompts();

    final saved = await service.togglePrompt(
      prompt: 'The plan is fine, but the timing needs work.',
      sourceLabel: 'Text Challenge',
    );
    final removed = await service.togglePrompt(
      prompt: 'The plan is fine, but the timing needs work.',
      sourceLabel: 'Text Challenge',
    );

    expect(saved, isTrue);
    expect(removed, isFalse);
    expect(service.savedPromptCount, 0);
  });
}
