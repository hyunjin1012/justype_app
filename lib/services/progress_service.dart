import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class PracticeSession {
  final String practiceType;
  final String prompt;
  final bool isCorrect;
  final int wordCount;
  final int elapsedSeconds;
  final int timestamp;

  const PracticeSession({
    required this.practiceType,
    required this.prompt,
    required this.isCorrect,
    required this.wordCount,
    required this.elapsedSeconds,
    required this.timestamp,
  });

  int get wordsPerMinute {
    if (!isCorrect || elapsedSeconds <= 0 || wordCount <= 0) {
      return 0;
    }

    return ((wordCount / elapsedSeconds) * 60).round();
  }

  Map<String, dynamic> toJson() {
    return {
      'practiceType': practiceType,
      'prompt': prompt,
      'isCorrect': isCorrect,
      'wordCount': wordCount,
      'elapsedSeconds': elapsedSeconds,
      'timestamp': timestamp,
    };
  }

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      practiceType: json['practiceType'] as String? ?? 'general',
      prompt: json['prompt'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      wordCount: json['wordCount'] as int? ?? 0,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }
}

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
  int _answerAttempts = 0;
  int _correctAnswers = 0;
  int _bestWordsPerMinute = 0;
  int _currentStreak = 0;
  int _dailyGoal = 5; // Example daily goal
  List<String> _recentAchievements = []; // List to store recent achievements
  List<String> _allAchievements =
      []; // Add a new field to track all achievements
  bool _isInitialized = false;
  int _dailyExercises = 0;
  String _lastExerciseDate = '';
  String _lastAiChallengeDate =
      ''; // Legacy field for older saved progress data
  String _lastTextAiChallengeDate =
      ''; // Legacy field for older saved progress data
  String _lastAudioAiChallengeDate =
      ''; // Legacy field for older saved progress data
  String _lastBooksAudioChallengeDate =
      ''; // Legacy field for older saved progress data
  Map<String, dynamic> _achievementData =
      {}; // Map of achievement ID to timestamp
  List<PracticeSession> _sessionHistory = [];
  List<String> _weakPrompts = [];
  Set<String> _practicedPromptKeys = {};
  String _lastSpeechTranslationDate =
      ''; // Add new field for tracking last speech translation

  // Map of achievement IDs to their descriptive messages
  final Map<String, String> _achievementMessages = {
    'text_10': 'Completed 10 text challenges!',
    'text_20': 'Completed 20 text challenges!',
    'audio_10': 'Completed 10 audio challenges!',
    'translation_10': 'Completed 10 phrase challenges!',
    'exercises_5': 'Completed 5 exercises!',
    'exercises_10': 'Completed 10 exercises!',
    'exercises_50': 'Completed 50 exercises!',
    'streak_3': 'Maintained a 3-day streak!',
    'streak_7': 'Maintained a 7-day streak!',
    'accuracy_90': 'Reached 90% answer accuracy!',
    'speed_30': 'Reached 30 words per minute!',
    'weak_clear': 'Cleared every weak prompt!',
  };

  // Getter for achievement messages
  Map<String, String> get achievementMessages => _achievementMessages;

  // Load progress from persistent storage
  Future<void> loadProgress() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _totalExercises = prefs.getInt('totalExercises') ?? 0;
    _textChallenges = prefs.getInt('textChallenges') ?? 0;
    _audioChallenges = prefs.getInt('audioChallenges') ?? 0;
    _translationChallenges = prefs.getInt('translationChallenges') ?? 0;
    _accuracyPercentage = prefs.getDouble('accuracyPercentage') ?? 0.0;
    _answerAttempts = prefs.getInt('answerAttempts') ?? 0;
    _correctAnswers = prefs.getInt('correctAnswers') ?? 0;
    _bestWordsPerMinute = prefs.getInt('bestWordsPerMinute') ?? 0;
    _currentStreak = prefs.getInt('currentStreak') ?? 0;
    _dailyGoal = prefs.getInt('dailyGoal') ?? 5;
    _dailyExercises = prefs.getInt('dailyExercises') ?? 0;
    _lastExerciseDate = prefs.getString('lastExerciseDate') ?? '';
    _lastAiChallengeDate = prefs.getString('lastAiChallengeDate') ?? '';
    _lastTextAiChallengeDate = prefs.getString('lastTextAiChallengeDate') ?? '';
    _lastAudioAiChallengeDate =
        prefs.getString('lastAudioAiChallengeDate') ?? '';
    _lastBooksAudioChallengeDate =
        prefs.getString('lastBooksAudioChallengeDate') ?? '';
    _lastSpeechTranslationDate =
        prefs.getString('lastSpeechTranslationDate') ?? '';
    _weakPrompts = prefs.getStringList('weakPrompts') ?? [];
    _practicedPromptKeys =
        (prefs.getStringList('practicedPromptKeys') ?? []).toSet();

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

    final sessionHistoryJson = prefs.getString('sessionHistory') ?? '[]';
    try {
      final decoded = json.decode(sessionHistoryJson) as List<dynamic>;
      _sessionHistory = decoded
          .map((item) =>
              PracticeSession.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      _sessionHistory = [];
    }

    for (final session in _sessionHistory) {
      _markPromptPracticed(session.prompt);
    }

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
    await prefs.setInt('answerAttempts', _answerAttempts);
    await prefs.setInt('correctAnswers', _correctAnswers);
    await prefs.setInt('bestWordsPerMinute', _bestWordsPerMinute);
    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setInt('dailyGoal', _dailyGoal);
    await prefs.setStringList('recentAchievements', _recentAchievements);
    await prefs.setStringList('allAchievements', _allAchievements);
    await prefs.setInt('dailyExercises', _dailyExercises);
    await prefs.setString('lastExerciseDate', _lastExerciseDate);
    await prefs.setString('lastAiChallengeDate', _lastAiChallengeDate);
    await prefs.setString('lastTextAiChallengeDate', _lastTextAiChallengeDate);
    await prefs.setString(
        'lastAudioAiChallengeDate', _lastAudioAiChallengeDate);
    await prefs.setString(
        'lastBooksAudioChallengeDate', _lastBooksAudioChallengeDate);
    await prefs.setString(
        'lastSpeechTranslationDate', _lastSpeechTranslationDate);
    await prefs.setStringList('weakPrompts', _weakPrompts);
    await prefs.setStringList(
      'practicedPromptKeys',
      _practicedPromptKeys.toList(),
    );
    await prefs.setString(
      'sessionHistory',
      json.encode(_sessionHistory.map((session) => session.toJson()).toList()),
    );

    // Save achievement data
    await prefs.setString('achievementData', json.encode(_achievementData));

    // Notify listeners that progress has been updated
    notifyListeners();
  }

  // Method to check if there are recent achievements
  bool hasRecentAchievements() {
    return _recentAchievements.isNotEmpty;
  }

  Future<void> recordAnswerAttempt(
    bool isCorrect, {
    String practiceType = 'general',
    String prompt = '',
    String? promptKey,
    int wordCount = 0,
    int elapsedSeconds = 0,
  }) async {
    _recordAnswerAttemptInMemory(isCorrect);
    _recordSessionInMemory(
      practiceType: practiceType,
      prompt: prompt,
      promptKey: promptKey,
      isCorrect: isCorrect,
      wordCount: wordCount,
      elapsedSeconds: elapsedSeconds,
    );

    if (!isCorrect && prompt.trim().isNotEmpty) {
      _addWeakPrompt(prompt);
    }

    await saveProgress();
  }

  Future<void> completeExercise({
    String practiceType = 'general',
    String prompt = '',
    String? promptKey,
    int wordCount = 0,
    int elapsedSeconds = 0,
  }) async {
    // Check if we need to reset daily exercises (new day)
    _checkAndResetDailyExercises();

    _recordAnswerAttemptInMemory(true);
    _recordSessionInMemory(
      practiceType: practiceType,
      prompt: prompt,
      promptKey: promptKey,
      isCorrect: true,
      wordCount: wordCount,
      elapsedSeconds: elapsedSeconds,
    );
    _removeWeakPrompt(prompt);

    _totalExercises++;
    _dailyExercises++;

    // Track specific exercise types
    if (practiceType == 'text') {
      _textChallenges++;

      // Check for text-related achievements
      if (_textChallenges == 10) {
        _addAchievement('text_10');
      } else if (_textChallenges == 20) {
        _addAchievement('text_20');
      }
    } else if (practiceType == 'audio') {
      _audioChallenges++;

      // Check for audio-related achievements
      if (_audioChallenges == 10) {
        _addAchievement('audio_10');
      }
    } else if (practiceType == 'translation') {
      _translationChallenges++;
      // Update the last speech translation date
      await updateLastSpeechTranslationDate();

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
    await _updateStreak();

    // Update last exercise date
    _lastExerciseDate = DateTime.now().toString().split(' ')[0];

    await saveProgress(); // Save progress after completing an exercise
  }

  // Update the streak counter
  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPracticeDay = prefs.getInt('lastPracticeDay') ?? 0;
    final lastPracticeMonth = prefs.getInt('lastPracticeMonth') ?? 0;
    final lastPracticeYear = prefs.getInt('lastPracticeYear') ?? 0;

    final currentDay = DateTime.now().day;
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;

    if (lastPracticeDay == 0) {
      _currentStreak = 1;
    } else if (lastPracticeDay == currentDay &&
        lastPracticeMonth == currentMonth &&
        lastPracticeYear == currentYear) {
      // Streak remains the same.
    } else if (_isConsecutiveDay(
        lastPracticeDay, lastPracticeMonth, lastPracticeYear)) {
      _currentStreak++;
    } else {
      _currentStreak = 1;
    }

    await prefs.setInt('lastPracticeDay', currentDay);
    await prefs.setInt('lastPracticeMonth', currentMonth);
    await prefs.setInt('lastPracticeYear', currentYear);

    if (_currentStreak == 3) {
      _addAchievement('streak_3');
    } else if (_currentStreak == 7) {
      _addAchievement('streak_7');
    }
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
  int getAnswerAttempts() => _answerAttempts;
  int getCorrectAnswers() => _correctAnswers;
  int getBestWordsPerMinute() => _bestWordsPerMinute;
  int getCurrentStreak() => _currentStreak;
  int getDailyGoal() => _dailyGoal;
  int getDailyExercises() => _dailyExercises;

  // Method to get the daily goal progress as a fraction
  double getDailyGoalProgress() {
    if (_dailyGoal == 0) {
      return 0;
    }

    return _dailyExercises / _dailyGoal;
  }

  // Method to get recent achievements
  List<String> getAchievements() {
    // Convert achievement IDs to descriptive messages
    return _recentAchievements
        .map((id) => _achievementMessages[id] ?? id)
        .toList();
  }

  // Add a method to get all achievements
  List<String> getAllAchievements() {
    return _allAchievements;
  }

  List<PracticeSession> getSessionHistory({int limit = 10}) {
    return _sessionHistory.take(limit).toList();
  }

  List<String> getWeakPrompts() {
    return List.unmodifiable(_weakPrompts);
  }

  bool hasPracticedPrompt(String prompt) {
    return _practicedPromptKeys.contains(normalizePromptKey(prompt));
  }

  int getPracticedPromptCount(Iterable<String> prompts) {
    return prompts.where(hasPracticedPrompt).length;
  }

  List<String> getUnpracticedPrompts(Iterable<String> prompts) {
    return prompts.where((prompt) => !hasPracticedPrompt(prompt)).toList();
  }

  static String normalizePromptKey(String prompt) {
    return prompt
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Resets all progress data to initial values
  Future<void> resetAllProgress() async {
    // Reset all tracked statistics to initial values
    _totalExercises = 0;
    _textChallenges = 0;
    _audioChallenges = 0;
    _translationChallenges = 0;
    _accuracyPercentage = 0.0;
    _answerAttempts = 0;
    _correctAnswers = 0;
    _bestWordsPerMinute = 0;
    _currentStreak = 0;
    _dailyGoal = 5; // Reset to default value
    _recentAchievements = []; // Clear recent achievements
    _allAchievements = []; // Clear all achievements
    _dailyExercises = 0;
    _lastExerciseDate = '';
    _lastAiChallengeDate = ''; // Reset legacy challenge date
    _lastTextAiChallengeDate = ''; // Reset legacy challenge date
    _lastAudioAiChallengeDate = ''; // Reset legacy challenge date
    _lastBooksAudioChallengeDate = ''; // Reset legacy challenge date
    _lastSpeechTranslationDate = ''; // Reset last speech translation date

    _achievementData = {};
    _sessionHistory = [];
    _weakPrompts = [];
    _practicedPromptKeys = {};

    // Clear data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('totalExercises');
    await prefs.remove('textChallenges');
    await prefs.remove('audioChallenges');
    await prefs.remove('translationChallenges');
    await prefs.remove('accuracyPercentage');
    await prefs.remove('answerAttempts');
    await prefs.remove('correctAnswers');
    await prefs.remove('bestWordsPerMinute');
    await prefs.remove('currentStreak');
    await prefs.remove('dailyGoal');
    await prefs.remove('recentAchievements');
    await prefs.remove('allAchievements');
    await prefs.remove('dailyExercises');
    await prefs.remove('lastExerciseDate');
    await prefs.remove('lastAiChallengeDate');
    await prefs.remove('lastTextAiChallengeDate');
    await prefs.remove('lastAudioAiChallengeDate');
    await prefs.remove('lastBooksAudioChallengeDate');
    await prefs.remove('lastSpeechTranslationDate');
    await prefs.remove('achievementData');
    await prefs.remove('sessionHistory');
    await prefs.remove('weakPrompts');
    await prefs.remove('practicedPromptKeys');

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

  void _recordAnswerAttemptInMemory(bool isCorrect) {
    _answerAttempts++;
    if (isCorrect) {
      _correctAnswers++;
    }

    _accuracyPercentage =
        _answerAttempts == 0 ? 0 : (_correctAnswers / _answerAttempts) * 100;

    if (_answerAttempts >= 10 && _accuracyPercentage >= 90) {
      _addAchievement('accuracy_90');
    }
  }

  void _recordSessionInMemory({
    required String practiceType,
    required String prompt,
    String? promptKey,
    required bool isCorrect,
    required int wordCount,
    required int elapsedSeconds,
  }) {
    final session = PracticeSession(
      practiceType: practiceType,
      prompt: prompt,
      isCorrect: isCorrect,
      wordCount: wordCount,
      elapsedSeconds: elapsedSeconds,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _markPromptPracticed(promptKey ?? prompt);

    _sessionHistory.insert(0, session);
    if (_sessionHistory.length > 40) {
      _sessionHistory = _sessionHistory.take(40).toList();
    }

    if (session.wordsPerMinute > _bestWordsPerMinute) {
      _bestWordsPerMinute = session.wordsPerMinute;
      if (_bestWordsPerMinute >= 30) {
        _addAchievement('speed_30');
      }
    }
  }

  void _addWeakPrompt(String prompt) {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) return;

    _weakPrompts.removeWhere(
      (existing) => existing.toLowerCase() == normalizedPrompt.toLowerCase(),
    );
    _weakPrompts.insert(0, normalizedPrompt);

    if (_weakPrompts.length > 20) {
      _weakPrompts = _weakPrompts.take(20).toList();
    }
  }

  void _markPromptPracticed(String prompt) {
    final key = normalizePromptKey(prompt);
    if (key.isNotEmpty) {
      _practicedPromptKeys.add(key);
    }
  }

  void _removeWeakPrompt(String prompt) {
    final normalizedPrompt = prompt.trim().toLowerCase();
    if (normalizedPrompt.isEmpty) return;

    final hadWeakPrompts = _weakPrompts.isNotEmpty;
    _weakPrompts.removeWhere(
      (existing) => existing.trim().toLowerCase() == normalizedPrompt,
    );

    if (hadWeakPrompts && _weakPrompts.isEmpty) {
      _addAchievement('weak_clear');
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

  // Legacy compatibility methods. Local modes are always available.
  bool isAiChallengeAvailableToday() {
    return true;
  }

  bool isBooksAudioChallengeAvailableToday() {
    return true;
  }

  bool isSpeechTranslationAvailableToday() {
    return true;
  }

  bool isTextAiChallengeAvailableToday() {
    return true;
  }

  bool isAudioAiChallengeAvailableToday() {
    return true;
  }

  // Legacy update methods kept so old call sites and saved data stay harmless.
  Future<void> updateLastAiChallengeDate() async {
    _lastAiChallengeDate = DateTime.now().toString().split(' ')[0];
    await saveProgress();
  }

  // Legacy update method for older saved progress data
  Future<void> updateLastTextAiChallengeDate() async {
    _lastTextAiChallengeDate = DateTime.now().toString().split(' ')[0];
    await saveProgress();
  }

  // Legacy update method for older saved progress data
  Future<void> updateLastAudioAiChallengeDate() async {
    _lastAudioAiChallengeDate = DateTime.now().toString().split(' ')[0];
    await saveProgress();
  }

  // Legacy update method for older saved progress data
  Future<void> updateLastBooksAudioChallengeDate() async {
    _lastBooksAudioChallengeDate = DateTime.now().toString().split(' ')[0];
    await saveProgress();
  }

  // Add method to update last speech translation date
  Future<void> updateLastSpeechTranslationDate() async {
    _lastSpeechTranslationDate = DateTime.now().toString().split(' ')[0];
    await saveProgress();
  }

  // Other methods to update accuracy, streak, etc.
}
