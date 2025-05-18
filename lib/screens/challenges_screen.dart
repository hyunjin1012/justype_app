import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/progress_service.dart';
import 'package:provider/provider.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late ProgressService _progressService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeProgress();
  }

  Future<void> _initializeProgress() async {
    _progressService = Provider.of<ProgressService>(context, listen: false);
    await _progressService.loadProgress();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final textChallenges = _progressService.getTextChallenges();
    final audioChallenges = _progressService.getAudioChallenges();
    final translationChallenges = _progressService.getTranslationChallenges();
    final isTextAiAvailable =
        _progressService.isTextAiChallengeAvailableToday();
    final isAudioAiAvailable =
        _progressService.isAudioAiChallengeAvailableToday();
    final isBooksAudioAvailable =
        _progressService.isBooksAudioChallengeAvailableToday();

    final List<Map<String, dynamic>> challenges = [
      {
        'title': 'Text Challenge',
        'description': 'Type the text you see on screen',
        'icon': Icons.menu_book,
        'color': Colors.blue.shade100,
        'route': '/challenges/text',
        'progress': textChallenges,
        'total': 50, // Example total
        'subtitle': 'Type what you see',
        'modes': [
          {
            'name': 'Books',
            'available': true,
            'limit': 'Unlimited',
          },
          {
            'name': 'AI',
            'available': isTextAiAvailable,
            'limit': 'Once per day',
          },
        ],
      },
      {
        'title': 'Audio Challenge',
        'description': 'Type what you hear',
        'icon': Icons.hearing,
        'color': Colors.green.shade100,
        'route': '/challenges/audio',
        'progress': audioChallenges,
        'total': 50, // Example total
        'subtitle': 'Listen and type',
        'modes': [
          {
            'name': 'Books',
            'available': isBooksAudioAvailable,
            'limit': 'Once per day',
          },
          {
            'name': 'AI',
            'available': isAudioAiAvailable,
            'limit': 'Once per day',
          },
        ],
      },
      {
        'title': 'Speech Translation',
        'description': 'Speak and type the translation',
        'icon': Icons.translate,
        'color': Colors.orange.shade100,
        'route': '/challenges/translate',
        'progress': translationChallenges,
        'total': 50, // Example total
        'subtitle': 'Speak and type',
        'modes': [
          {
            'name': 'Translation',
            'available': _progressService.isSpeechTranslationAvailableToday(),
            'limit': 'Once per day',
          },
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to Type?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a challenge and start typing. Track your progress and unlock achievements as you go.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),

            // Statistics section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        'Total Sessions',
                        _progressService.getTotalExercises().toString(),
                        Icons.emoji_events,
                        Colors.amber,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        'Current Streak',
                        '${_progressService.getCurrentStreak()} days',
                        Icons.local_fire_department,
                        Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Challenges grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Challenge',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GestureDetector(
                          onTap: () {
                            // Check if all modes are unavailable
                            final allModesUnavailable = challenge['modes']
                                .every((mode) => !mode['available']);
                            if (!allModesUnavailable) {
                              GoRouter.of(context).go(challenge['route']);
                            }
                          },
                          child: Card(
                            elevation: 2,
                            color: challenge['color'],
                            // Add opacity when all modes are unavailable
                            child: Opacity(
                              opacity: challenge['modes']
                                      .every((mode) => !mode['available'])
                                  ? 0.5
                                  : 1.0,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          challenge['icon'],
                                          size: 28,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.black87
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                challenge['title'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.black87
                                                      : null,
                                                ),
                                              ),
                                              Text(
                                                challenge['subtitle'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.black87
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Show modes and their availability
                                    ...challenge['modes'].map<Widget>((mode) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              mode['available']
                                                  ? Icons.check_circle
                                                  : Icons.timer,
                                              size: 16,
                                              color: mode['available']
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${mode['name']}: ${mode['limit']}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: mode['available']
                                                    ? Colors.black87
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    // Add message when all modes are unavailable
                                    if (challenge['modes']
                                        .every((mode) => !mode['available']))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'All modes used for today. Try again tomorrow!',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
