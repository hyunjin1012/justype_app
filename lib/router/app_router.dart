import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/reading_practice_screen.dart';
import '../screens/listening_practice_screen.dart';
import '../screens/book_list_screen.dart';
import '../screens/book_detail_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/reading',
    navigatorKey: _rootNavigatorKey,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/reading',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReadingPracticeScreen(),
            ),
          ),
          GoRoute(
            path: '/listening',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ListeningPracticeScreen(),
            ),
          ),
          GoRoute(
            path: '/books',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BookListScreen(),
            ),
          ),
        ],
      ),
      // This route is not part of the bottom navigation
      GoRoute(
        path: '/book/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final bookId = state.pathParameters['id']!;
          return BookDetailScreen(bookId: bookId);
        },
      ),
    ],
  );
}
