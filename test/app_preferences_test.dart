import 'package:flutter_test/flutter_test.dart';
import 'package:justype/services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new installs show onboarding', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await AppPreferences.shouldShowOnboarding(), isTrue);
  });

  test('completed onboarding skips onboarding', () async {
    SharedPreferences.setMockInitialValues({});

    await AppPreferences.completeOnboarding();

    expect(await AppPreferences.shouldShowOnboarding(), isFalse);
  });

  test('legacy first launch flag is migrated to onboarding complete', () async {
    SharedPreferences.setMockInitialValues({
      AppPreferences.firstLaunchKey: false,
    });

    expect(await AppPreferences.shouldShowOnboarding(), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppPreferences.onboardingCompleteKey), isTrue);
  });

  test('reset onboarding shows onboarding again', () async {
    SharedPreferences.setMockInitialValues({});

    await AppPreferences.completeOnboarding();
    await AppPreferences.resetOnboarding();

    expect(await AppPreferences.shouldShowOnboarding(), isTrue);
  });
}
