# JusType

JusType is an offline-first Flutter practice app for text, audio, and conversation phrase drills.

## Product direction

JusType is strongest as a lightweight offline shadowing trainer: users can type or dictate prompts, listen and reproduce sentences, and practice local conversation phrase packs without relying on paid or unstable APIs.

Implemented product layers:

- Weak-prompt drills based on missed answers.
- Scenario phrase packs for conversation practice, including travel, cafe, small talk, apology, classroom, interview, and daily-life prompts.
- Session history with accuracy, elapsed time, word count, and personal best WPM.
- App-wide positioning around offline practice, keyboard plus microphone input, and privacy-friendly local content.

The next high-value additions are:

- Weak-word extraction inside a missed sentence, not just full-prompt review.
- Streak recovery and richer weekly trend charts.
- More polished scenario packs with native-speaker review.
- App Store screenshots and a short preview video that highlight offline shadowing practice.

## Offline-first content

The core practice flows do not depend on OpenAI, ElevenLabs, Gutendex, Project Gutenberg APIs, or unofficial translation endpoints.

- Text and audio practice use the bundled local library in `assets/corpus/books.json`.
- Generated practice uses `GeneratedSentenceService`, a local sentence generator.
- Phrase practice uses bundled scenario packs in `assets/translations/phrase_packs.json`.
- Audio playback uses platform text-to-speech through `flutter_tts`.

The app still uses device/platform capabilities such as speech recognition and local TTS, but it no longer makes external API calls for its core content.

## Content policy

Practice content should be original to JusType, licensed for app use, or safely public domain. Do not add modern song lyrics, copyrighted dialogue, quotes from current books, or other protected text unless the rights are cleared. For a lyrics-like feel, use original rhythm packs or verified public-domain classics instead.

## Development

```sh
flutter pub get
flutter analyze
flutter test
```
