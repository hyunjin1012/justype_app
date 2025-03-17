import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if first launch to show onboarding
  final prefs = await SharedPreferences.getInstance();
  final bool showOnboarding = prefs.getBool('first_launch') ?? true;

  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatefulWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen for theme changes
    AppRouter.themeService.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Language Practice App',
      theme: AppRouter.themeService.getThemeData(),
      darkTheme: AppRouter.themeService.darkTheme,
      themeMode: AppRouter.themeService.themeMode,
      routerConfig: AppRouter.router,
    );
  }
}
