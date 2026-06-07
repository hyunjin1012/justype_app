import 'package:flutter/material.dart';
import '../widgets/achievement_banner.dart';
import '../widgets/app_surface.dart';
import '../services/progress_service.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final ProgressService _progressService = ProgressService();
  bool _needsRefresh = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progressService.addListener(_onProgressUpdated);
    _loadProgress(); // Load progress when the screen is initialized
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressService.removeListener(_onProgressUpdated);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came to foreground, refresh data
      _loadProgress();
    }
  }

  // This method will be called when this screen is navigated to
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
      });
    }
  }

  Future<void> _loadProgress() async {
    await _progressService.loadProgress();
    if (mounted) {
      setState(() {
        // Refresh UI with latest data
      });
    }
  }

  // Pull-to-refresh functionality
  Future<void> _refreshData() async {
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    // Get achievements to display
    final achievements = _progressService.getAchievements();
    final bool showAchievementBanner = _progressService.hasRecentAchievements();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        actions: [
          // Add reset button in the app bar
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Reset All Progress',
            onPressed: _showResetConfirmationDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Achievement banner - only show if there are achievements
            if (showAchievementBanner && achievements.isNotEmpty)
              AchievementBanner(
                title: 'Congratulations!',
                description: achievements.last,
                icon: 'assets/animations/achievement.json',
                backgroundColor: Provider.of<ThemeService>(context).accentColor,
                textColor: Colors.white,
                onDismiss: () {
                  // Clear recent achievements when dismissed
                  _progressService.clearRecentAchievements();
                  setState(() {});
                },
              ),

            const SizedBox(height: 24),

            _buildSkillOverview(),

            const SizedBox(height: 24),

            // Progress stats
            AppSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Stats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    'Today\'s Sessions',
                    '${_progressService.getDailyExercises()}',
                  ),
                  _buildStatRow(
                    'Total Sessions',
                    '${_progressService.getTotalExercises()}',
                  ),
                  _buildStatRow(
                    'Answer Accuracy',
                    _progressService.getAnswerAttempts() == 0
                        ? '--'
                        : '${_progressService.getAccuracyPercentage().round()}%',
                  ),
                  _buildStatRow(
                    'Answer Attempts',
                    '${_progressService.getAnswerAttempts()}',
                  ),
                  _buildStatRow(
                    'Text Sessions',
                    '${_progressService.getTextChallenges()}',
                  ),
                  _buildStatRow(
                    'Audio Sessions',
                    '${_progressService.getAudioChallenges()}',
                  ),
                  _buildStatRow(
                    'Translation Sessions',
                    '${_progressService.getTranslationChallenges()}',
                  ),
                  _buildStatRow(
                    'Current Streak',
                    '${_progressService.getCurrentStreak()} ${_progressService.getCurrentStreak() == 1 ? 'day' : 'days'}',
                  ),
                  _buildStatRow(
                    'Daily Goal',
                    '${_progressService.getDailyGoal()} sessions',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Daily goal progress
            _buildDailyGoalProgress(),

            const SizedBox(height: 24),

            _buildSessionHistory(),

            const SizedBox(height: 24),

            // Recent achievements
            _buildAllAchievements(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillOverview() {
    final attempts = _progressService.getAnswerAttempts();
    final correct = _progressService.getCorrectAnswers();
    final accuracy = _progressService.getAccuracyPercentage();

    return Row(
      children: [
        _buildOverviewCard(
          title: 'Accuracy',
          value: attempts == 0 ? '--' : '${accuracy.round()}%',
          detail: '$correct of $attempts correct',
          icon: Icons.track_changes,
          color: Colors.indigo,
        ),
        const SizedBox(width: 12),
        _buildOverviewCard(
          title: 'Best Speed',
          value: '${_progressService.getBestWordsPerMinute()}',
          detail: 'words per minute',
          icon: Icons.local_fire_department,
          color: Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required String detail,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
        ],
      ),
    );
  }

  Widget _buildDailyGoalProgress() {
    final dailyExercises = _progressService.getDailyExercises();
    final dailyGoal = _progressService.getDailyGoal();
    final progress = dailyExercises / dailyGoal;
    final themeService = Provider.of<ThemeService>(context);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Goal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progress >= 1.0
                      ? themeService.accentColor.withValues(alpha: 0.1)
                      : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$dailyExercises/$dailyGoal sessions',
                  style: TextStyle(
                    color: progress >= 1.0
                        ? themeService.accentColor
                        : Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                LinearProgressIndicator(
                  value: progress > 1.0 ? 1.0 : progress,
                  minHeight: 20,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0
                        ? themeService.accentColor
                        : Theme.of(context).primaryColor,
                  ),
                ),
                if (progress > 0)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          color: progress > 0.5 ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (progress >= 1.0)
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Daily goal completed! Great job!',
                  style: TextStyle(
                    color: themeService.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.directions_run,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Keep going! You\'re doing great!',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSessionHistory() {
    final sessions = _progressService.getSessionHistory(limit: 8);

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.indigo, size: 28),
              const SizedBox(width: 8),
              Text(
                'Recent Sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.history_toggle_off,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'No sessions yet. Complete a prompt to start tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            )
          else
            ...sessions.map((session) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  session.isCorrect ? Icons.check_circle : Icons.error,
                  color: session.isCorrect ? Colors.green : Colors.red,
                ),
                title: Text(
                  _formatPracticeType(session.practiceType),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  session.prompt.isEmpty
                      ? _formatSessionDetail(session)
                      : '${_formatSessionDetail(session)} • ${session.prompt}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  session.wordsPerMinute == 0
                      ? _formatSessionAge(session.timestamp)
                      : '${session.wordsPerMinute} WPM',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatPracticeType(String practiceType) {
    switch (practiceType) {
      case 'text':
        return 'Text Practice';
      case 'audio':
        return 'Listening Practice';
      case 'translation':
        return 'Translation Practice';
      case 'weak':
        return 'Weak Drill';
      default:
        return 'Practice';
    }
  }

  String _formatSessionDetail(PracticeSession session) {
    final result = session.isCorrect ? 'Correct' : 'Missed';
    final duration =
        session.elapsedSeconds <= 0 ? '--' : '${session.elapsedSeconds}s';
    final words = session.wordCount <= 0 ? '--' : '${session.wordCount} words';
    return '$result • $words • $duration';
  }

  String _formatSessionAge(int timestamp) {
    if (timestamp == 0) {
      return '';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return 'Now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h';
    }

    return '${difference.inDays}d';
  }

  Widget _buildAllAchievements() {
    final achievements = _progressService.getAllAchievements();
    final achievementMessages = _progressService.achievementMessages;

    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text(
                'Achievements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (achievements.isEmpty)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.hourglass_empty,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'No achievements yet. Start typing today!',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievementId = achievements[index];
                final achievementMessage =
                    achievementMessages[achievementId] ?? achievementId;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getAchievementColor(achievementId)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _getAchievementIcon(achievementId),
                        color: _getAchievementColor(achievementId),
                      ),
                      title: Text(
                        achievementMessage,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        _getAchievementDate(achievementId),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Helper methods for achievements
  IconData _getAchievementIcon(String achievementId) {
    if (achievementId.contains('exercises')) {
      return Icons.fitness_center;
    } else if (achievementId.contains('streak')) {
      return Icons.local_fire_department;
    } else if (achievementId.contains('text')) {
      return Icons.menu_book;
    } else if (achievementId.contains('audio')) {
      return Icons.hearing;
    } else if (achievementId.contains('translation')) {
      return Icons.translate;
    }
    return Icons.emoji_events;
  }

  Color _getAchievementColor(String achievementId) {
    if (achievementId.contains('exercises')) {
      return Colors.purple;
    } else if (achievementId.contains('streak')) {
      return Colors.orange;
    } else if (achievementId.contains('text')) {
      return Colors.blue;
    } else if (achievementId.contains('audio')) {
      return Colors.green;
    } else if (achievementId.contains('translation')) {
      return Colors.teal;
    }
    return Colors.amber;
  }

  String _getAchievementDate(String achievementId) {
    final timestamp = _progressService.getAchievementTimestamp(achievementId);
    if (timestamp == 0) {
      return "Unknown";
    }

    final achievementDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(achievementDate);

    if (difference.inMinutes < 1) {
      return "Just now";
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return "$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago";
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return "$hours ${hours == 1 ? 'hour' : 'hours'} ago";
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return "$days ${days == 1 ? 'day' : 'days'} ago";
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return "$months ${months == 1 ? 'month' : 'months'} ago";
    } else {
      final years = (difference.inDays / 365).floor();
      return "$years ${years == 1 ? 'year' : 'years'} ago";
    }
  }

  Future<void> _showResetConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset All Progress'),
          content: const SingleChildScrollView(
            child: Text(
              'This will erase all your progress, achievements, and statistics. '
              'This action cannot be undone. Are you sure you want to continue?',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Reset Everything'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetAllProgress();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetAllProgress() async {
    await _progressService.resetAllProgress();
    if (mounted) {
      setState(() {
        // Refresh UI after reset
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All progress has been reset'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
