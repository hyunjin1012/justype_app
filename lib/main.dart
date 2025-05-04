import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'router/app_router.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables from root directory
    await dotenv.load(fileName: ".env");
    print('Environment variables loaded successfully');
    print(
        'API Key: ${dotenv.env['OPENAI_API_KEY']?.substring(0, 10)}...'); // Print first 10 chars for verification
  } catch (e) {
    print('Error loading environment variables: $e');
    print('Current working directory: ${Directory.current.path}');
    // Continue running the app even if .env loading fails
  }

  // Check if first launch to show onboarding
  final prefs = await SharedPreferences.getInstance();
  final bool showOnboarding = prefs.getBool('first_launch') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        // Add other providers here
      ],
      child: MyApp(showOnboarding: showOnboarding),
    ),
  );
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
