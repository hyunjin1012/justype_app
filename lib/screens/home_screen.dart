import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/achievement_banner.dart';
import '../widgets/app_surface.dart';
import '../services/progress_service.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProgressService _progressService = ProgressService();
  bool _needsRefresh = true;

  @override
  void initState() {
    super.initState();
    // Listen for progress updates
    _progressService.addListener(_onProgressUpdated);
    _loadProgress();
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    _progressService.removeListener(_onProgressUpdated);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_needsRefresh) {
      _loadProgress();
      _needsRefresh = false;
    }
  }

  // Called when progress is updated
  void _onProgressUpdated() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild with the latest progress data
        _needsRefresh =
            false; // We've just refreshed, so no need to refresh again
      });
    }
  }

  Future<void> _loadProgress() async {
    await _progressService.loadProgress();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get achievements to display
    final achievements = _progressService.getAchievements();
    final bool showAchievementBanner = _progressService.hasRecentAchievements();

    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('JusType'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => GoRouter.of(context).push('/settings'),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadProgress,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily goal progress
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildDailyGoalCard(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSkillSnapshot(context),
                    ),

                    // Show achievement banner if there are recent achievements
                    if (showAchievementBanner && achievements.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: AchievementBanner(
                          title: 'New Achievement!',
                          description: achievements.last,
                          icon: 'assets/animations/achievement.json',
                          backgroundColor: Colors.amber.shade100,
                          textColor: Colors.brown,
                          onDismiss: () {
                            // Clear recent achievements when dismissed
                            _progressService.clearRecentAchievements();
                            setState(() {});
                          },
                        ),
                      ),

                    // Practice modes section
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: SectionTitle(title: 'Today\'s Practice'),
                    ),

                    // Practice mode cards
                    _buildPracticeModeCards(context),

                    // Recommended books section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: SectionTitle(
                        title: 'Explore Stories',
                        actionLabel: 'View All',
                        onAction: () => GoRouter.of(context).go('/books'),
                      ),
                    ),

                    // Recommended books carousel
                    SizedBox(
                      height: 224,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: 5, // Example count
                        itemBuilder: (context, index) {
                          return _buildBookCard(context, index);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyGoalCard(BuildContext context) {
    final dailyExercises = _progressService.getDailyExercises();
    final dailyGoal = _progressService.getDailyGoal();
    final progress = dailyExercises / dailyGoal;
    final goalText = '$dailyExercises/$dailyGoal sessions';
    final themeService = Provider.of<ThemeService>(context);

    return AppSurface(
      onTap: () => GoRouter.of(context).push('/dashboard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Goal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                goalText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress > 1.0 ? 1.0 : progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0
                  ? themeService.accentColor
                  : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          if (progress >= 1.0)
            Text(
              'Daily goal completed! Great job!',
              style: TextStyle(
                color: themeService.accentColor,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              'A short session is enough to keep the streak alive.',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPracticeModeCards(BuildContext context) {
    final List<Map<String, dynamic>> practiceModes = [
      {
        'title': 'Text',
        'description': 'Read, type, or dictate precise sentences',
        'icon': Icons.keyboard,
        'color': Colors.blue.shade100,
        'route': '/challenges/text',
      },
      {
        'title': 'Listening',
        'description': 'Hear a line and reproduce it accurately',
        'icon': Icons.hearing,
        'color': Colors.green.shade100,
        'route': '/challenges/audio',
      },
      {
        'title': 'Phrases',
        'description': 'Practice conversation packs by voice or text',
        'icon': Icons.translate,
        'color': Colors.orange.shade100,
        'route': '/challenges/translate',
      },
      {
        'title': 'Weak Drills',
        'description': _progressService.getWeakPrompts().isEmpty
            ? 'Missed prompts will collect here'
            : 'Review ${_progressService.getWeakPrompts().length} missed prompts',
        'icon': Icons.psychology,
        'color': Colors.purple.shade100,
        'route': '/challenges/weak',
      },
    ];

    final Map<String, dynamic> libraryMode = {
      'title': 'Library',
      'description': 'Browse bundled offline practice passages',
      'icon': Icons.library_books,
      'color': Colors.teal.shade100,
      'route': '/books',
    };

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.32,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: practiceModes.length,
          itemBuilder: (context, index) {
            final mode = practiceModes[index];
            return AppSurface(
              onTap: () => GoRouter.of(context).go(mode['route']),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: (mode['color'] as Color).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      mode['icon'],
                      size: 21,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mode['title'],
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode['description'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AppSurface(
            onTap: () => GoRouter.of(context).go(libraryMode['route']),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        (libraryMode['color'] as Color).withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    libraryMode['icon'],
                    size: 22,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        libraryMode['title'],
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        libraryMode['description'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillSnapshot(BuildContext context) {
    final accuracy = _progressService.getAccuracyPercentage();
    final attempts = _progressService.getAnswerAttempts();

    return Row(
      children: [
        _buildMetricPill(
          context,
          label: 'Accuracy',
          value: attempts == 0 ? '--' : '${accuracy.round()}%',
          icon: Icons.track_changes,
          color: Colors.indigo,
        ),
        const SizedBox(width: 8),
        _buildMetricPill(
          context,
          label: 'Streak',
          value: '${_progressService.getCurrentStreak()}d',
          icon: Icons.local_fire_department,
          color: Colors.deepOrange,
        ),
        const SizedBox(width: 8),
        _buildMetricPill(
          context,
          label: 'Sessions',
          value: '${_progressService.getTotalExercises()}',
          icon: Icons.bolt,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildMetricPill(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, int index) {
    final List<Map<String, dynamic>> recommendedBooks = [
      {
        'id': '1020',
        'title': 'Missed Train',
        'author': 'JusType Originals',
        'subject': 'Travel',
        'icon': Icons.train,
      },
      {
        'id': '1025',
        'title': 'Cafe Argument',
        'author': 'JusType Originals',
        'subject': 'Conversation',
        'icon': Icons.chat_bubble_outline,
      },
      {
        'id': '1030',
        'title': 'Morning Brief',
        'author': 'JusType Originals',
        'subject': 'Work',
        'icon': Icons.work_outline,
      },
      {
        'id': '1037',
        'title': 'Phone Call',
        'author': 'JusType Originals',
        'subject': 'Family',
        'icon': Icons.call_outlined,
      },
      {
        'id': '1058',
        'title': 'Elevator Pitch',
        'author': 'JusType Originals',
        'subject': 'Confidence',
        'icon': Icons.record_voice_over,
      },
    ];

    // If index is out of bounds, return an empty container
    if (index >= recommendedBooks.length) {
      return Container();
    }

    final book = recommendedBooks[index];

    return GestureDetector(
      onTap: () {
        // Navigate to book detail screen
        GoRouter.of(context).push('/book/${book['id']}');
      },
      child: Container(
        width: 132,
        margin: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Container(
              height: 136,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _homeCoverColor(context, index),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Theme.of(context).dividerTheme.color ??
                      Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      book['icon'],
                      size: 22,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    book['subject'],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Book title
            Text(
              book['title'],
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Book author
            Text(
              book['author'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _homeCoverColor(BuildContext context, int index) {
    final theme = Theme.of(context);
    final palette = [
      theme.colorScheme.tertiaryContainer,
      theme.colorScheme.secondaryContainer,
      theme.colorScheme.primaryContainer,
      theme.colorScheme.surfaceContainerHighest,
      theme.colorScheme.errorContainer,
    ];

    return palette[index % palette.length];
  }
}
