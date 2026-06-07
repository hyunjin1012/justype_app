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
  ];

  Future<Map<String, dynamic>> generateSentence() async {
    final useTemplate = _random.nextBool();
    final sentence = useTemplate ? _buildTemplateSentence() : _pickStandalone();

    return {
      'content': sentence,
      'bookTitle': 'Generated Practice',
      'bookAuthor': 'Local sentence engine',
      'currentBookId': '',
    };
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
