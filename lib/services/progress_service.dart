import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking and managing user progress
class ProgressService extends ChangeNotifier {
  // Example properties to track progress
  int _totalExercises = 0;
  int _readingExercises = 0;
  int _listeningExercises = 0;
  double _accuracyPercentage = 0.0;
  int _currentStreak = 0;
  int _dailyGoal = 5; // Example daily goal
  List<String> _recentAchievements = []; // List to store recent achievements

  // Load progress from persistent storage
  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _totalExercises = prefs.getInt('totalExercises') ?? 0;
    _readingExercises = prefs.getInt('readingExercises') ?? 0;
    _listeningExercises = prefs.getInt('listeningExercises') ?? 0;
    _accuracyPercentage = prefs.getDouble('accuracyPercentage') ?? 0.0;
    _currentStreak = prefs.getInt('currentStreak') ?? 0;
    _dailyGoal = prefs.getInt('dailyGoal') ?? 5;

    // Load recent achievements if stored
    _recentAchievements = prefs.getStringList('recentAchievements') ?? [];
  }

  // Save progress to persistent storage
  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalExercises', _totalExercises);
    await prefs.setInt('readingExercises', _readingExercises);
    await prefs.setInt('listeningExercises', _listeningExercises);
    await prefs.setDouble('accuracyPercentage', _accuracyPercentage);
    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setInt('dailyGoal', _dailyGoal);
    await prefs.setStringList('recentAchievements', _recentAchievements);

    // Notify listeners that progress has been updated
    notifyListeners();
  }

  // Method to check if there are recent achievements
  bool hasRecentAchievements() {
    return _recentAchievements.isNotEmpty;
  }

  // Example methods to update progress
  void completeExercise({String practiceType = 'general'}) {
    _totalExercises++;

    // Track specific exercise types
    if (practiceType == 'reading') {
      _readingExercises++;

      // Check for reading-specific achievements
      if (_readingExercises == 10) {
        _recentAchievements.add('reading_10');
      } else if (_readingExercises == 20) {
        _recentAchievements.add('reading_20');
      }
    } else if (practiceType == 'listening') {
      _listeningExercises++;

      // Check for listening-specific achievements
      if (_listeningExercises == 10) {
        _recentAchievements.add('listening_10');
      }
    }

    // Check for general achievements
    if (_totalExercises == 10) {
      _recentAchievements.add('exercises_10');
    } else if (_totalExercises == 50) {
      _recentAchievements.add('exercises_50');
    }

    // Update streak logic
    _updateStreak();

    saveProgress(); // Save progress after completing an exercise
  }

  // Update the streak counter
  void _updateStreak() {
    // Get the current date
    final today = DateTime.now().day;

    // In a real app, you'd compare with the last practice date
    // For this example, we'll just increment the streak
    _currentStreak++;

    // Check for streak achievements
    if (_currentStreak == 3) {
      _recentAchievements.add('streak_3');
    } else if (_currentStreak == 7) {
      _recentAchievements.add('streak_7');
    }
  }

  // Getters for progress metrics
  int getTotalExercises() => _totalExercises;
  int getReadingExercises() => _readingExercises;
  int getListeningExercises() => _listeningExercises;
  double getAccuracyPercentage() => _accuracyPercentage;
  int getCurrentStreak() => _currentStreak;
  int getDailyGoal() => _dailyGoal;

  // Method to get the daily goal progress as a fraction
  double getDailyGoalProgress() {
    // Assuming daily goal is the target number of exercises to complete
    return _totalExercises / _dailyGoal; // Returns a value between 0 and 1
  }

  // Method to get recent achievements
  List<String> getAchievements() {
    return _recentAchievements; // Return the list of recent achievements
  }

  // Other methods to update accuracy, streak, etc.
}
