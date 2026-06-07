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
        'available': true,
        'status': '$textChallenges sessions completed',
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
        'available': true,
        'status': '$audioChallenges sessions completed',
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
        'title': 'Phrase Practice',
        'description': 'Answer local conversation prompts in English',
        'icon': Icons.translate,
        'color': Colors.orange.shade100,
        'route': '/challenges/translate',
        'progress': translationChallenges,
        'total': 25,
        'subtitle': 'Scenario conversation',
        'available': true,
        'status': '$translationChallenges phrase sessions completed',
        'modes': [
          {
            'name': 'Phrase Packs',
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
        'available': weakPromptCount > 0,
        'status': weakPromptCount == 0
            ? 'Missed prompts will appear here'
            : '$weakPromptCount prompts waiting',
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
                      'Offline drills for typing, dictation, listening recall, and conversation phrases.',
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
                      final isLocked = challenge['available'] == false;
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
                                Row(
                                  children: [
                                    Icon(
                                      isLocked
                                          ? Icons.schedule
                                          : Icons.check_circle,
                                      size: 16,
                                      color: isLocked
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        challenge['status'],
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
}
