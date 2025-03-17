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
    _loadProgress(); // Load progress when the screen is initialized
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Achievement banner
            const AchievementBanner(
              title: 'Congratulations!',
              description: 'You have completed 10 exercises!',
              icon: 'assets/animations/achievement.json',
              backgroundColor: Colors.green,
              textColor: Colors.white,
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
                    _buildStatRow('Total Exercises',
                        '${_progressService.getTotalExercises()}'),
                    _buildStatRow('Reading Exercises',
                        '${_progressService.getReadingExercises()}'),
                    _buildStatRow('Listening Exercises',
                        '${_progressService.getListeningExercises()}'),
                    _buildStatRow('Current Streak',
                        '${_progressService.getCurrentStreak()} days'),
                    _buildStatRow('Daily Goal',
                        '${_progressService.getDailyGoal()} exercises'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent achievements
            _buildRecentAchievements(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStats() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
                'Total Exercises', '${_progressService.getTotalExercises()}'),
            _buildStatRow(
                'Accuracy', '${_progressService.getAccuracyPercentage()}%'),
            _buildStatRow('Current Streak',
                '${_progressService.getCurrentStreak()} days'),
            _buildStatRow(
                'Daily Goal', '${_progressService.getDailyGoal()} exercises'),
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

  Widget _buildRecentAchievements() {
    final achievements = _progressService.getAchievements();

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
}
