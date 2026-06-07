import 'dart:math';

import 'progress_service.dart';

class GeneratedSentenceService {
  final Random _random = Random();
  static List<String>? _sentencePool;

  static const List<String> _openers = [
    'A careful learner',
    'The practice session',
    'Every focused minute',
    'A steady routine',
    'The quiet workspace',
    'Clear instructions',
    'A useful notebook',
    'The final revision',
    'The late train',
    'A nervous speaker',
    'The unread message',
    'A small apology',
    'A focused commute',
    'The first clear draft',
    'A crowded kitchen',
    'The quiet library',
    'A delayed reply',
    'The morning checklist',
    'A patient teammate',
    'The open notebook',
    'A careful question',
    'The evening reminder',
    'A useful correction',
    'The short rehearsal',
  ];

  static const List<String> _verbs = [
    'turns small corrections into lasting skill',
    'makes difficult patterns easier to repeat',
    'keeps attention close to the next word',
    'builds confidence through patient repetition',
    'helps each sentence feel more natural',
    'reveals the places where accuracy improves',
    'gives the hands a reliable rhythm',
    'connects speed with calm precision',
    'moves through the city with a secret deadline',
    'finds courage inside one steady breath',
    'waits on the screen longer than expected',
    'opens the door to a better conversation',
    'makes the next attempt feel easier to begin',
    'keeps the important details close enough to notice',
    'changes a rushed reaction into a thoughtful answer',
    'gives the conversation a steadier direction',
    'turns a difficult phrase into something familiar',
    'helps the whole room understand the plan',
    'finds the missing step before the deadline moves',
    'makes ordinary practice feel useful again',
    'protects attention from the loudest distraction',
    'turns one honest sentence into forward motion',
    'shows where confidence needs another repetition',
    'keeps the work small enough to finish',
  ];

  static const List<String> _endings = [
    'before the next challenge begins.',
    'during a short and focused drill.',
    'without depending on a network request.',
    'while the page stays simple and quiet.',
    'as progress gathers one line at a time.',
    'when the goal is clear from the start.',
    'after every answer is checked with care.',
    'because reliable practice is easier to trust.',
    'while rain gathers in the crosswalk.',
    'before the room has time to doubt it.',
    'as the last notification fades.',
    'without turning honesty into a performance.',
    'while the answer is still fresh.',
    'before the afternoon gets too crowded.',
    'with enough patience to make it stick.',
    'as the page fills with cleaner choices.',
    'before anyone needs to guess again.',
    'while the room stays calm and attentive.',
    'after the confusing part finally makes sense.',
    'without making the moment heavier than it is.',
    'as the small deadline comes into view.',
    'before the learner reaches for another hint.',
    'with a little more courage than yesterday.',
    'while the next sentence waits its turn.',
  ];

  static const List<String> _standaloneSentences = [
    'Reliable practice starts with one accurate sentence and a calm reset.',
    'The fastest improvement often comes from slowing down for the hard part.',
    'A clear prompt lets the learner focus on rhythm, recall, and precision.',
    'Progress becomes visible when small sessions are easy to repeat.',
    'The best typing drills remove distractions and reward careful attention.',
    'A simple local library can keep practice available anywhere.',
    'Short sentences help beginners build confidence before longer passages.',
    'A consistent routine turns ordinary minutes into useful training.',
    'I can be nervous and still choose the next honest sentence.',
    'The city looked ordinary until the message arrived without a name.',
    'Please save me a seat near the window if you get there first.',
    'The best apology makes the next moment lighter, not louder.',
    'I can ask a clearer question before I assume the answer.',
    'The message sounded ordinary until the final sentence changed everything.',
    'Please move the meeting if the morning train is delayed again.',
    'A steady hand can make a messy paragraph feel possible.',
    'The honest version was shorter and easier to remember.',
    'I noticed the mistake early enough to fix it calmly.',
    'The room became quieter after someone named the real problem.',
    'A useful routine should survive an imperfect day.',
    'The next reply can be both kind and direct.',
    'I will practice the hard phrase until it stops surprising me.',
    'The better plan arrived after everyone stopped rushing.',
    'Small progress still counts when the day is complicated.',
  ];

  static const List<String> _rhythmLines = [
    'I left my keys beside the raincoat and walked into the morning.',
    'A bright mistake can still teach the hands where to land.',
    'The last train hummed like it knew where everyone had been.',
    'Some promises are small enough to keep before breakfast.',
    'I wrote the softer sentence and meant it more than the sharp one.',
    'A careful breath can turn panic into a plan.',
    'The sentence landed softly and changed the whole room.',
    'I kept the note because it sounded like a second chance.',
    'The sidewalk shone after rain and made the city look edited.',
    'A quiet answer can still carry a brave decision.',
    'The clock moved slowly while I practiced the opening line.',
    'I found the right words after deleting the dramatic ones.',
  ];

  static const List<String> _sceneLines = [
    'The cafe door stuck twice before the stranger pushed it open.',
    'At gate seventeen, nobody agreed about which line was moving.',
    'The receipt in my pocket had an address I did not remember.',
    'A blue umbrella waited in the hallway with nobody under it.',
    'The elevator stopped on every floor except the one I needed.',
    'Someone had written good luck on the back of the wrong envelope.',
    'The bookstore receipt included a phone number nobody recognized.',
    'A silver suitcase circled the baggage belt without an owner.',
    'The apartment buzzer rang twice, then sent a text instead.',
    'The map showed a shortcut through a street that was not there.',
    'A handwritten menu changed prices whenever the lights flickered.',
    'The museum guard smiled before pointing to the hidden door.',
  ];

  static const List<String> _speechLines = [
    'Could you repeat the last part more slowly, please?',
    'I need a minute to think before I answer that clearly.',
    'That plan works for me if we move the time a little earlier.',
    'I am sorry for the delay, and I should have updated you sooner.',
    'I can explain the tradeoff if you want the short version first.',
    'Let us check the details now so tomorrow feels easier.',
    'Could you send the address again before I leave?',
    'I understand the concern, but I need one more example.',
    'That answer helps, and I want to confirm the next step.',
    'Please tell me what changed since the last version.',
    'I can take responsibility for the part I missed.',
    'Let us choose the simpler option and explain it clearly.',
  ];

  Future<Map<String, dynamic>> generateSentence() async {
    final progressService = ProgressService();
    await progressService.loadProgress();

    final unpracticedSentences = _allSentences
        .where((sentence) => !progressService.hasPracticedPrompt(sentence))
        .toList();

    if (unpracticedSentences.isEmpty) {
      return {
        'content': 'You have practiced every generated prompt.',
        'bookTitle': 'Generated Complete',
        'bookAuthor': 'Local sentence engine',
        'currentBookId': '',
      };
    }

    final sentence =
        unpracticedSentences[_random.nextInt(unpracticedSentences.length)];

    return {
      'content': sentence,
      'bookTitle': 'Generated Practice',
      'bookAuthor': 'Local sentence engine',
      'currentBookId': '',
    };
  }

  List<String> get _allSentences {
    return _sentencePool ??= _buildSentencePool();
  }

  static List<String> _buildSentencePool() {
    final sentences = <String>{};

    for (final opener in _openers) {
      for (final verb in _verbs) {
        for (final ending in _endings) {
          sentences.add('$opener $verb $ending');
        }
      }
    }

    sentences
      ..addAll(_standaloneSentences)
      ..addAll(_rhythmLines)
      ..addAll(_sceneLines)
      ..addAll(_speechLines);

    return sentences
        .where((sentence) => sentence.length >= 20 && sentence.length <= 200)
        .toList(growable: false);
  }
}
