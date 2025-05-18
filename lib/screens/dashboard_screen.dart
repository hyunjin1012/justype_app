import 'package:flutter/material.dart';
import '../widgets/achievement_banner.dart';
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
        title: const Text('Your Stats'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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

            // Progress stats
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Practice Statistics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Today\'s Exercises',
                        '${_progressService.getDailyExercises()}'),
                    _buildStatRow('Total Exercises',
                        '${_progressService.getTotalExercises()}'),
                    _buildStatRow('Text Challenges',
                        '${_progressService.getTextChallenges()}'),
                    _buildStatRow('Audio Challenges',
                        '${_progressService.getAudioChallenges()}'),
                    _buildStatRow('Translation Challenges',
                        '${_progressService.getTranslationChallenges()}'),
                    _buildStatRow('Current Streak',
                        '${_progressService.getCurrentStreak()} ${_progressService.getCurrentStreak() == 1 ? 'day' : 'days'}'),
                    _buildStatRow('Daily Goal',
                        '${_progressService.getDailyGoal()} exercises'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Daily goal progress
            _buildDailyGoalProgress(),

            // Recent achievements
            _buildAllAchievements(),
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

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        ? themeService.accentColor.withOpacity(0.1)
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$dailyExercises/$dailyGoal exercises',
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
                    'Keep going! You\'re making progress!',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAchievements() {
    final achievements = _progressService.getAllAchievements();
    final achievementMessages = _progressService.achievementMessages;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      'No achievements yet. Keep practicing!',
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
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: _getAchievementColor(achievementId).withOpacity(0.1),
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
                  );
                },
              ),
          ],
        ),
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
