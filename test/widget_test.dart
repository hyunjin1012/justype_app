import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:justype/main.dart';
import 'package:justype/services/app_preferences.dart';
import 'package:justype/services/progress_service.dart';
import 'package:justype/services/purchase_service.dart';
import 'package:justype/services/saved_prompt_service.dart';
import 'package:justype/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      AppPreferences.onboardingCompleteKey: true,
    });
  });

  testWidgets('JusType renders the main navigation', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => ProgressService()),
          ChangeNotifierProvider(create: (_) => PurchaseService()),
          ChangeNotifierProvider(create: (_) => SavedPromptService()),
        ],
        child: const MyApp(showOnboarding: false),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Progress'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('JusType renders onboarding when requested', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => ProgressService()),
          ChangeNotifierProvider(create: (_) => PurchaseService()),
          ChangeNotifierProvider(create: (_) => SavedPromptService()),
        ],
        child: const MyApp(showOnboarding: true),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome to JusType'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('completing onboarding saves launch flags', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => ProgressService()),
          ChangeNotifierProvider(create: (_) => PurchaseService()),
          ChangeNotifierProvider(create: (_) => SavedPromptService()),
        ],
        child: const MyApp(showOnboarding: true),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppPreferences.firstLaunchKey), isFalse);
    expect(prefs.getBool(AppPreferences.onboardingCompleteKey), isTrue);
    expect(find.text('Home'), findsWidgets);
  });
}
