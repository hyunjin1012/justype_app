import 'package:flutter/material.dart';
import '../widgets/achievement_banner.dart';
import '../services/progress_service.dart';

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
                description: _formatAchievementName(achievements.last),
                icon: 'assets/animations/achievement.json',
                backgroundColor: Colors.green,
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
                    _buildStatRow('Reading Exercises',
                        '${_progressService.getReadingExercises()}'),
                    _buildStatRow('Listening Exercises',
                        '${_progressService.getListeningExercises()}'),
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

    return Card(
      elevation: 2,
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
                Text(
                  '$dailyExercises/$dailyGoal exercises',
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
                progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            if (progress >= 1.0)
              const Text(
                'Daily goal completed! Great job!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                'Keep going!',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllAchievements() {
    final achievements = _progressService.getAllAchievements();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (achievements.isEmpty)
              const Text('No achievements yet. Keep practicing!')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return ListTile(
                    leading:
                        const Icon(Icons.emoji_events, color: Colors.amber),
                    title: Text(_formatAchievementName(achievement)),
                    dense: true,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatAchievementName(String achievementId) {
    // Convert achievement IDs to readable names
    switch (achievementId) {
      case 'exercises_5':
        return 'Completed 5 exercises';
      case 'exercises_10':
        return 'Completed 10 exercises';
      case 'exercises_50':
        return 'Completed 50 exercises';
      case 'streak_3':
        return '3-day practice streak';
      case 'streak_7':
        return '7-day practice streak';
      case 'reading_10':
        return 'Completed 10 reading exercises';
      case 'reading_20':
        return 'Completed 20 reading exercises';
      case 'listening_10':
        return 'Completed 10 listening exercises';
      default:
        return achievementId;
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
