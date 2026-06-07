import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/progress_service.dart';
import '../widgets/app_surface.dart';
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
    final weakPromptCount = _progressService.getWeakPrompts().length;

    final List<Map<String, dynamic>> challenges = [
      {
        'title': 'Text Challenge',
        'description': 'Reproduce clean prompts with keyboard or mic',
        'icon': Icons.menu_book,
        'color': Colors.blue.shade100,
        'route': '/challenges/text',
        'progress': textChallenges,
        'total': 25,
        'subtitle': 'Precision practice',
        'modes': [
          {
            'name': 'Library',
            'available': true,
            'limit': 'Unlimited',
          },
          {
            'name': 'Generated',
            'available': true,
            'limit': 'Unlimited',
          },
        ],
      },
      {
        'title': 'Audio Challenge',
        'description': 'Listen first, then match the sentence',
        'icon': Icons.hearing,
        'color': Colors.green.shade100,
        'route': '/challenges/audio',
        'progress': audioChallenges,
        'total': 25,
        'subtitle': 'Listening recall',
        'modes': [
          {
            'name': 'Library',
            'available': true,
            'limit': 'Unlimited',
          },
          {
            'name': 'Generated',
            'available': true,
            'limit': 'Unlimited',
          },
        ],
      },
      {
        'title': 'Speech Translation',
        'description': 'Shadow local phrase packs into English',
        'icon': Icons.translate,
        'color': Colors.orange.shade100,
        'route': '/challenges/translate',
        'progress': translationChallenges,
        'total': 25,
        'subtitle': 'Bilingual shadowing',
        'modes': [
          {
            'name': 'Translation',
            'available': true,
            'limit': 'Unlimited',
          },
        ],
      },
      {
        'title': 'Weak Drills',
        'description': 'Review prompts you missed in any mode',
        'icon': Icons.psychology,
        'color': Colors.purple.shade100,
        'route': '/challenges/weak',
        'progress': weakPromptCount,
        'total': weakPromptCount == 0 ? 1 : weakPromptCount,
        'subtitle': 'Focused review',
        'lockedMessage':
            'No weak prompts yet. Miss an answer in another mode to build this drill.',
        'modes': [
          {
            'name': 'Review Queue',
            'available': weakPromptCount > 0,
            'limit': weakPromptCount == 0
                ? 'No prompts yet'
                : '$weakPromptCount waiting',
          },
        ],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Practice?',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Offline drills for typing, dictation, listening recall, and translation shadowing.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // Statistics section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Your Progress'),
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        'Accuracy',
                        _progressService.getAnswerAttempts() == 0
                            ? '--'
                            : '${_progressService.getAccuracyPercentage().round()}%',
                        Icons.track_changes,
                        Colors.indigo,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        'Attempts',
                        '${_progressService.getAnswerAttempts()}',
                        Icons.fact_check,
                        Colors.teal,
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
                  const SectionTitle(title: 'Choose Your Challenge'),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      final challenge = challenges[index];
                      final modes = challenge['modes'] as List<dynamic>;
                      final isLocked =
                          modes.every((mode) => !mode['available']);
                      final Color accentColor = challenge['color'] as Color;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Opacity(
                          opacity: isLocked ? 0.56 : 1.0,
                          child: AppSurface(
                            onTap: isLocked
                                ? null
                                : () =>
                                    GoRouter.of(context).go(challenge['route']),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color:
                                            accentColor.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        challenge['icon'],
                                        size: 24,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            challenge['title'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          Text(
                                            challenge['subtitle'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  challenge['description'],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                ...modes.map<Widget>((mode) {
                                  final isAvailable = mode['available'] as bool;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isAvailable
                                              ? Icons.check_circle
                                              : Icons.schedule,
                                          size: 16,
                                          color: isAvailable
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${mode['name']}: ${mode['limit']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                if (isLocked)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      challenge['lockedMessage'] ??
                                          'This challenge is unavailable right now.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                  ),
                              ],
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
      child: AppSurface(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
