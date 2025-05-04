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
import '../screens/challenges_screen.dart';
import '../services/theme_service.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _homeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'home');
  static final _dashboardNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'dashboard');
  static final _challengesNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'challenges');
  static final _booksNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'books');

  static final ThemeService themeService = ThemeService();

  // Create static instances of screens to preserve their state
  static const homeScreen = HomeScreen();
  static const dashboardScreen = DashboardScreen();
  static const challengesScreen = ChallengesScreen();
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
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNavBar(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return IndexedStack(
            index: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => homeScreen,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => dashboardScreen,
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/challenges',
                builder: (context, state) => challengesScreen,
              ),
              GoRoute(
                path: '/challenges/text',
                builder: (context, state) => const TextChallengeScreen(),
              ),
              GoRoute(
                path: '/challenges/audio',
                builder: (context, state) => const AudioChallengeScreen(),
              ),
              GoRoute(
                path: '/challenges/translate',
                builder: (context, state) => const SpeechTranslationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/books',
                builder: (context, state) => booksScreen,
              ),
              GoRoute(
                path: '/book/:id',
                builder: (context, state) => BookDetailScreen(
                  bookId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),

      // Routes not part of the bottom navigation
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
            icon: Icon(Icons.games),
            label: 'Challenges',
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
        // Don't set initialLocation to false to prevent rebuilding
      );
    }
  }
}
