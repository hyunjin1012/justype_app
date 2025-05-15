import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Service for tracking and managing user progress
class ProgressService extends ChangeNotifier {
  // Singleton instance
  static final ProgressService _instance = ProgressService._internal();

  // Factory constructor to return the same instance
  factory ProgressService() {
    return _instance;
  }

  // Private constructor for singleton
  ProgressService._internal();

  // Example properties to track progress
  int _totalExercises = 0;
  int _textChallenges = 0;
  int _audioChallenges = 0;
  int _translationChallenges = 0;
  double _accuracyPercentage = 0.0;
  int _currentStreak = 0;
  int _dailyGoal = 5; // Example daily goal
  List<String> _recentAchievements = []; // List to store recent achievements
  List<String> _allAchievements =
      []; // Add a new field to track all achievements
  bool _isInitialized = false;
  int _dailyExercises = 0;
  String _lastExerciseDate = '';
  String _lastAiChallengeDate =
      ''; // Add new field for tracking last AI challenge
  String _lastBooksAudioChallengeDate =
      ''; // Add new field for tracking last Books audio challenge
  Map<String, dynamic> _achievementData =
      {}; // Map of achievement ID to timestamp

  // Load progress from persistent storage
  Future<void> loadProgress() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _totalExercises = prefs.getInt('totalExercises') ?? 0;
    _textChallenges = prefs.getInt('textChallenges') ?? 0;
    _audioChallenges = prefs.getInt('audioChallenges') ?? 0;
    _translationChallenges = prefs.getInt('translationChallenges') ?? 0;
    _accuracyPercentage = prefs.getDouble('accuracyPercentage') ?? 0.0;
    _currentStreak = prefs.getInt('currentStreak') ?? 0;
    _dailyGoal = prefs.getInt('dailyGoal') ?? 5;
    _dailyExercises = prefs.getInt('dailyExercises') ?? 0;
    _lastExerciseDate = prefs.getString('lastExerciseDate') ?? '';
    _lastAiChallengeDate = prefs.getString('lastAiChallengeDate') ??
        ''; // Load last AI challenge date
    _lastBooksAudioChallengeDate =
        prefs.getString('lastBooksAudioChallengeDate') ?? '';

    // Load recent achievements if stored
    _recentAchievements = prefs.getStringList('recentAchievements') ?? [];

    // Load achievement data
    final achievementDataJson = prefs.getString('achievementData') ?? '{}';
    try {
      _achievementData =
          Map<String, dynamic>.from(json.decode(achievementDataJson) as Map);
    } catch (e) {
      _achievementData = {};
    }

    // Load all achievements
    _allAchievements = prefs.getStringList('allAchievements') ?? [];

    // Ensure all achievements have timestamps
    for (final achievement in _allAchievements) {
      if (!_achievementData.containsKey(achievement)) {
        // If we have an achievement without timestamp data, add it with current time
        _achievementData[achievement] = DateTime.now().millisecondsSinceEpoch;
      }
    }

    // Check if we need to reset daily exercises (new day)
    _checkAndResetDailyExercises();

    _isInitialized = true;
    notifyListeners();
  }

  // Save progress to persistent storage
  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalExercises', _totalExercises);
    await prefs.setInt('textChallenges', _textChallenges);
    await prefs.setInt('audioChallenges', _audioChallenges);
    await prefs.setInt('translationChallenges', _translationChallenges);
    await prefs.setDouble('accuracyPercentage', _accuracyPercentage);
    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setInt('dailyGoal', _dailyGoal);
    await prefs.setStringList('recentAchievements', _recentAchievements);
    await prefs.setStringList('allAchievements', _allAchievements);
    await prefs.setInt('dailyExercises', _dailyExercises);
    await prefs.setString('lastExerciseDate', _lastExerciseDate);
    await prefs.setString('lastAiChallengeDate',
        _lastAiChallengeDate); // Save last AI challenge date
    await prefs.setString(
        'lastBooksAudioChallengeDate', _lastBooksAudioChallengeDate);

    // Save achievement data
    await prefs.setString('achievementData', json.encode(_achievementData));

    // Notify listeners that progress has been updated
    notifyListeners();
  }

  // Method to check if there are recent achievements
  bool hasRecentAchievements() {
    return _recentAchievements.isNotEmpty;
  }

  // Example methods to update progress
  Future<void> completeExercise(
      {String practiceType = 'general', bool isAiChallenge = false}) async {
    // Check if we need to reset daily exercises (new day)
    _checkAndResetDailyExercises();

    _totalExercises++;
    _dailyExercises++;

    // Track specific exercise types
    if (practiceType == 'text') {
      _textChallenges++;

      // If it's an AI challenge, update the last AI challenge date
      if (isAiChallenge) {
        await updateLastAiChallengeDate();
      }

      // Check for text-related achievements
      if (_textChallenges == 10) {
        _addAchievement('text_10');
      } else if (_textChallenges == 20) {
        _addAchievement('text_20');
      }
    } else if (practiceType == 'audio') {
      _audioChallenges++;

      // If it's an AI challenge, update the last AI challenge date
      if (isAiChallenge) {
        await updateLastAiChallengeDate();
      } else {
        // If it's a Books audio challenge, update the last Books audio challenge date
        await updateLastBooksAudioChallengeDate();
      }

      // Check for audio-related achievements
      if (_audioChallenges == 10) {
        _addAchievement('audio_10');
      }
    } else if (practiceType == 'translation') {
      _translationChallenges++;

      // Check for translation-related achievements
      if (_translationChallenges == 10) {
        _addAchievement('translation_10');
      }
    }

    // Check for general achievements
    if (_totalExercises == 5) {
      _addAchievement('exercises_5');
    } else if (_totalExercises == 10) {
      _addAchievement('exercises_10');
    } else if (_totalExercises == 50) {
      _addAchievement('exercises_50');
    }

    // Update streak logic
    _updateStreak();

    // Update last exercise date
    _lastExerciseDate = DateTime.now().toString().split(' ')[0];

    await saveProgress(); // Save progress after completing an exercise
  }

  // Update the streak counter
  void _updateStreak() {
    // Get the current date
    // final today = DateTime.now().day;

    // Get the last practice date from SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      final lastPracticeDay = prefs.getInt('lastPracticeDay') ?? 0;
      final lastPracticeMonth = prefs.getInt('lastPracticeMonth') ?? 0;
      final lastPracticeYear = prefs.getInt('lastPracticeYear') ?? 0;

      final currentDay = DateTime.now().day;
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;

      // If this is the first practice ever
      if (lastPracticeDay == 0) {
        _currentStreak = 1;
      }
      // If practiced today already, don't change streak
      else if (lastPracticeDay == currentDay &&
          lastPracticeMonth == currentMonth &&
          lastPracticeYear == currentYear) {
        // Streak remains the same
      }
      // If practiced yesterday, increment streak
      else if (_isConsecutiveDay(
          lastPracticeDay, lastPracticeMonth, lastPracticeYear)) {
        _currentStreak++;
      }
      // If missed a day, reset streak
      else {
        _currentStreak = 1;
      }

      // Save the current date as the last practice date
      prefs.setInt('lastPracticeDay', currentDay);
      prefs.setInt('lastPracticeMonth', currentMonth);
      prefs.setInt('lastPracticeYear', currentYear);

      // Check for streak achievements
      if (_currentStreak == 3) {
        _addAchievement('streak_3');
      } else if (_currentStreak == 7) {
        _addAchievement('streak_7');
      }
    });
  }

  // Helper method to check if the last practice was yesterday
  bool _isConsecutiveDay(int lastDay, int lastMonth, int lastYear) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    return lastDay == yesterday.day &&
        lastMonth == yesterday.month &&
        lastYear == yesterday.year;
  }

  // Getters for progress metrics
  int getTotalExercises() => _totalExercises;
  int getTextChallenges() => _textChallenges;
  int getAudioChallenges() => _audioChallenges;
  int getTranslationChallenges() => _translationChallenges;
  double getAccuracyPercentage() => _accuracyPercentage;
  int getCurrentStreak() => _currentStreak;
  int getDailyGoal() => _dailyGoal;
  int getDailyExercises() => _dailyExercises;

  // Method to get the daily goal progress as a fraction
  double getDailyGoalProgress() {
    // Assuming daily goal is the target number of exercises to complete
    return _totalExercises / _dailyGoal; // Returns a value between 0 and 1
  }

  // Method to get recent achievements
  List<String> getAchievements() {
    return _recentAchievements; // Return the list of recent achievements
  }

  // Add a method to get all achievements
  List<String> getAllAchievements() {
    return _allAchievements;
  }

  /// Resets all progress data to initial values
  Future<void> resetAllProgress() async {
    // Reset all tracked statistics to initial values
    _totalExercises = 0;
    _textChallenges = 0;
    _audioChallenges = 0;
    _translationChallenges = 0;
    _accuracyPercentage = 0.0;
    _currentStreak = 0;
    _dailyGoal = 5; // Reset to default value
    _recentAchievements = []; // Clear recent achievements
    _allAchievements = []; // Clear all achievements
    _dailyExercises = 0;
    _lastExerciseDate = '';
    _lastAiChallengeDate = ''; // Reset last AI challenge date
    _lastBooksAudioChallengeDate = ''; // Reset last Books audio challenge date

    _achievementData = {};

    // Clear data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('totalExercises');
    await prefs.remove('textChallenges');
    await prefs.remove('audioChallenges');
    await prefs.remove('translationChallenges');
    await prefs.remove('accuracyPercentage');
    await prefs.remove('currentStreak');
    await prefs.remove('dailyGoal');
    await prefs.remove('recentAchievements');
    await prefs.remove('allAchievements');
    await prefs.remove('dailyExercises');
    await prefs.remove('lastExerciseDate');
    await prefs.remove('lastAiChallengeDate');
    await prefs.remove('lastBooksAudioChallengeDate');
    await prefs.remove('achievementData');

    // Clear streak tracking data
    await prefs.remove('lastPracticeDay');
    await prefs.remove('lastPracticeMonth');
    await prefs.remove('lastPracticeYear');

    // Notify listeners that progress has been reset
    notifyListeners();
  }

  // Method to clear recent achievements after they've been shown
  Future<void> clearRecentAchievements() async {
    _recentAchievements = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recentAchievements', _recentAchievements);
    notifyListeners();
  }

  // Add a method to check and reset daily exercises
  void _checkAndResetDailyExercises() {
    final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format

    if (_lastExerciseDate != today) {
      // It's a new day, reset daily exercises
      _dailyExercises = 0;
      _lastExerciseDate = today;
    }
  }

  // Helper method to add an achievement with timestamp
  void _addAchievement(String achievementId) {
    if (!_allAchievements.contains(achievementId)) {
      _recentAchievements.add(achievementId);
      _allAchievements.add(achievementId);
      _achievementData[achievementId] = DateTime.now().millisecondsSinceEpoch;
    }
  }

  // Add a method to get achievement timestamp
  int getAchievementTimestamp(String achievementId) {
    return _achievementData[achievementId] ?? 0;
  }

  // Add method to check if AI challenge is available today
  bool isAiChallengeAvailableToday() {
    final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format
    return _lastAiChallengeDate != today;
  }

  // Add method to check if Books audio challenge is available today
  bool isBooksAudioChallengeAvailableToday() {
    final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD format
    return _lastBooksAudioChallengeDate != today;
  }

  // Add method to update last AI challenge date
  Future<void> updateLastAiChallengeDate() async {
    _lastAiChallengeDate = DateTime.now().toString().split(' ')[0];
    await saveProgress();
  }

  // Add method to update last Books audio challenge date
  Future<void> updateLastBooksAudioChallengeDate() async {
    _lastBooksAudioChallengeDate = DateTime.now().toString().split(' ')[0];
    await saveProgress();
  }

  // Other methods to update accuracy, streak, etc.
}
