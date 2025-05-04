import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/text_challenge_screen.dart';
import '../screens/audio_challenge_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/speech_translation_screen.dart';
import '../services/theme_service.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _homeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'home');
  static final _dashboardNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'dashboard');
  static final _readingNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'reading');
  static final _listeningNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'listening');
  static final _speechTranslationNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'speech_translation');
  static final _booksNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'books');

  static final ThemeService themeService = ThemeService();

  // Create static instances of screens to preserve their state
  static const homeScreen = HomeScreen();
  static const dashboardScreen = DashboardScreen();
  static const textChallengeScreen = TextChallengeScreen();
  static const audioChallengeScreen = AudioChallengeScreen();
  static const booksScreen = BookListScreen();

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    navigatorKey: _rootNavigatorKey,
    routes: [
      // Onboarding route (shown only first time)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Use StatefulShellRoute for bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home branch
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Dashboard branch
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Reading branch
          StatefulShellBranch(
            navigatorKey: _readingNavigatorKey,
            routes: [
              GoRoute(
                path: '/text',
                builder: (context, state) => const TextChallengeScreen(),
              ),
            ],
          ),
          // Listening branch
          StatefulShellBranch(
            navigatorKey: _listeningNavigatorKey,
            routes: [
              GoRoute(
                path: '/audio',
                builder: (context, state) => const AudioChallengeScreen(),
              ),
            ],
          ),
          // Speech Translation branch
          StatefulShellBranch(
            navigatorKey: _speechTranslationNavigatorKey,
            routes: [
              GoRoute(
                path: '/speech-translation',
                builder: (context, state) => const SpeechTranslationScreen(),
              ),
            ],
          ),
          // Books branch
          StatefulShellBranch(
            navigatorKey: _booksNavigatorKey,
            routes: [
              GoRoute(
                path: '/books',
                builder: (context, state) => const BookListScreen(),
              ),
            ],
          ),
        ],
      ),

      // Routes not part of the bottom navigation
      GoRoute(
        path: '/book/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return BookDetailScreen(bookId: bookId);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return SettingsScreen(themeService: themeService);
        },
      ),
    ],
  );
}

// New widget to replace ScaffoldWithNavBar
class ScaffoldWithBottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Text',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hearing),
            label: 'Audio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.translate),
            label: 'Translate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Books',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    // Only navigate if the tab is not already selected
    if (index != navigationShell.currentIndex) {
      navigationShell.goBranch(
        index,
        // Set initial location if it's the first visit to this tab
        initialLocation: index == navigationShell.currentIndex,
      );
    }
  }
}
