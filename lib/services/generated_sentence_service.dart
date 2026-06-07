import 'dart:math';

class GeneratedSentenceService {
  final Random _random = Random();

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
  ];

  static const List<String> _rhythmLines = [
    'I left my keys beside the raincoat and walked into the morning.',
    'A bright mistake can still teach the hands where to land.',
    'The last train hummed like it knew where everyone had been.',
    'Some promises are small enough to keep before breakfast.',
    'I wrote the softer sentence and meant it more than the sharp one.',
    'A careful breath can turn panic into a plan.',
  ];

  static const List<String> _sceneLines = [
    'The cafe door stuck twice before the stranger pushed it open.',
    'At gate seventeen, nobody agreed about which line was moving.',
    'The receipt in my pocket had an address I did not remember.',
    'A blue umbrella waited in the hallway with nobody under it.',
    'The elevator stopped on every floor except the one I needed.',
    'Someone had written good luck on the back of the wrong envelope.',
  ];

  static const List<String> _speechLines = [
    'Could you repeat the last part more slowly, please?',
    'I need a minute to think before I answer that clearly.',
    'That plan works for me if we move the time a little earlier.',
    'I am sorry for the delay, and I should have updated you sooner.',
    'I can explain the tradeoff if you want the short version first.',
    'Let us check the details now so tomorrow feels easier.',
  ];

  Future<Map<String, dynamic>> generateSentence() async {
    final sentence = _pickGenerator()();

    return {
      'content': sentence,
      'bookTitle': 'Generated Practice',
      'bookAuthor': 'Local sentence engine',
      'currentBookId': '',
    };
  }

  String Function() _pickGenerator() {
    final generators = [
      _buildTemplateSentence,
      _pickStandalone,
      () => _pick(_rhythmLines),
      () => _pick(_sceneLines),
      () => _pick(_speechLines),
    ];

    return generators[_random.nextInt(generators.length)];
  }

  String _buildTemplateSentence() {
    final sentence = '${_pick(_openers)} ${_pick(_verbs)} ${_pick(_endings)}';

    if (sentence.length >= 20 && sentence.length <= 200) {
      return sentence;
    }

    return _pickStandalone();
  }

  String _pickStandalone() {
    return _pick(_standaloneSentences);
  }

  String _pick(List<String> values) {
    return values[_random.nextInt(values.length)];
  }
}
