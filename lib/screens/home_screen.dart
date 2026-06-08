import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/achievement_banner.dart';
import '../widgets/app_surface.dart';
import '../services/progress_service.dart';
import 'package:provider/provider.dart';
import '../services/purchase_service.dart';
import '../services/saved_prompt_service.dart';
import '../services/theme_service.dart';
import '../widgets/plus_purchase_sheet.dart';

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
    final achievements = _progressService.getAchievements();
    final bool showAchievementBanner = _progressService.hasRecentAchievements();

    return Scaffold(
      appBar: AppBar(
        title: const Text('JusType'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStartPracticeCard(context),
              const SizedBox(height: 12),
              _buildDailyGoalCard(context),
              const SizedBox(height: 12),
              _buildSkillSnapshot(context),
              if (showAchievementBanner && achievements.isNotEmpty) ...[
                const SizedBox(height: 12),
                AchievementBanner(
                  title: 'New Achievement!',
                  description: achievements.last,
                  icon: 'assets/animations/achievement.json',
                  backgroundColor: Colors.amber.shade100,
                  textColor: Colors.brown,
                  onDismiss: () {
                    _progressService.clearRecentAchievements();
                    setState(() {});
                  },
                ),
              ],
              const SizedBox(height: 20),
              const SectionTitle(title: 'More Practice'),
              const SizedBox(height: 12),
              _buildPracticeModeCards(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartPracticeCard(BuildContext context) {
    final theme = Theme.of(context);

    return AppSurface(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.keyboard,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ready for a session?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Typing, dictation, and saved-prompt practice in short offline sessions.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => GoRouter.of(context).go('/challenges/text'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Typing'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => GoRouter.of(context).go('/challenges/audio'),
                child: const Text('Dictation'),
              ),
            ],
          ),
        ],
      ),
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
    final weakPromptCount = _progressService.getWeakPrompts().length;

    return Consumer2<PurchaseService, SavedPromptService>(
      builder: (context, purchaseService, savedPromptService, child) {
        return Column(
          children: [
            _buildPracticeRow(
              context,
              title: 'Library',
              description: 'Browse offline prompt packs',
              icon: Icons.library_books,
              color: Colors.teal,
              route: '/books',
            ),
            if (weakPromptCount > 0) ...[
              const SizedBox(height: 12),
              _buildPracticeRow(
                context,
                title: 'Weak Drills',
                description: '$weakPromptCount missed prompts waiting',
                icon: Icons.psychology,
                color: Colors.purple,
                route: '/challenges/weak',
              ),
            ],
            const SizedBox(height: 12),
            _buildSavedPromptsRow(
              context,
              purchaseService: purchaseService,
              savedPromptService: savedPromptService,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPracticeRow(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return AppSurface(
      onTap: () => GoRouter.of(context).go(route),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _buildModeIcon(context, icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }

  Widget _buildSavedPromptsRow(
    BuildContext context, {
    required PurchaseService purchaseService,
    required SavedPromptService savedPromptService,
  }) {
    final isPlusUnlocked = purchaseService.isPlusUnlocked;
    final savedCount = savedPromptService.savedPromptCount;
    final description = isPlusUnlocked
        ? savedCount == 0
            ? 'Add custom prompts or save favorites'
            : '$savedCount prompts ready to review'
        : 'Custom prompts and review queue';
    final iconColor = isPlusUnlocked
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return AppSurface(
      onTap: isPlusUnlocked
          ? () => GoRouter.of(context).go('/challenges/saved')
          : () => _showPlusSheet(context),
      padding: const EdgeInsets.all(14),
      color: isPlusUnlocked
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.35)
          : null,
      child: Row(
        children: [
          _buildModeIcon(
            context,
            icon: isPlusUnlocked ? Icons.bookmark : Icons.bookmark_border,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Prompts',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            isPlusUnlocked ? Icons.chevron_right : Icons.lock_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(
    BuildContext context, {
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 22,
        color: color,
      ),
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

  void _showPlusSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const PlusPurchaseSheet(),
    );
  }
}
