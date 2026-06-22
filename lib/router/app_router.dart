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
import '../screens/weak_drill_screen.dart';
import '../screens/saved_prompt_practice_screen.dart';
import '../screens/saved_prompt_review_screen.dart';
import '../screens/saved_prompts_screen.dart';
import '../services/theme_service.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Create static instances of screens to preserve their state
  static const homeScreen = HomeScreen();
  static const dashboardScreen = DashboardScreen();
  static const booksScreen = BookListScreen();

  static GoRouter createRouter(bool showOnboarding) {
    return GoRouter(
      initialLocation: showOnboarding ? '/onboarding' : '/home',
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
                GoRoute(
                  path: '/challenges',
                  redirect: (context, state) => '/home',
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
                  path: '/challenges/weak',
                  builder: (context, state) => const WeakDrillScreen(),
                ),
                GoRoute(
                  path: '/challenges/saved',
                  builder: (context, state) => const SavedPromptsScreen(),
                ),
                GoRoute(
                  path: '/challenges/saved/review',
                  builder: (context, state) => const SavedPromptReviewScreen(),
                ),
                GoRoute(
                  path: '/challenges/saved/practice/:id',
                  builder: (context, state) => SavedPromptPracticeScreen(
                    promptId: Uri.decodeComponent(
                      state.pathParameters['id'] ?? '',
                    ),
                  ),
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
                  path: '/settings',
                  builder: (context, state) {
                    return SettingsScreen(
                      themeService: Provider.of<ThemeService>(context),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
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
        iconSize: 24,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
