import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String firstLaunchKey = 'first_launch';
  static const String onboardingCompleteKey = 'onboarding_complete';

  const AppPreferences._();

  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool(onboardingCompleteKey);

    if (onboardingComplete != null) {
      return !onboardingComplete;
    }

    final firstLaunch = prefs.getBool(firstLaunchKey);
    if (firstLaunch == false) {
      await prefs.setBool(onboardingCompleteKey, true);
      return false;
    }

    return true;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(firstLaunchKey, false);
    await prefs.setBool(onboardingCompleteKey, true);
  }

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(firstLaunchKey, true);
    await prefs.setBool(onboardingCompleteKey, false);
  }
}
