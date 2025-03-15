import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/reading_practice_screen.dart';
import '../screens/listening_practice_screen.dart';
import '../screens/book_list_screen.dart';

class ScaffoldWithNavBar extends StatefulWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
  });

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  // Keep a list of the pages we want to maintain state for
  final List<Widget> _pages = [
    const ReadingPracticeScreen(),
    const ListeningPracticeScreen(),
    const BookListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to maintain state of all screens
      body: IndexedStack(
        index: _calculateSelectedIndex(context),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Reading',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hearing),
            label: 'Listening',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Books',
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (int idx) => _onItemTapped(idx, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/reading')) {
      return 0;
    }
    if (location.startsWith('/listening')) {
      return 1;
    }
    if (location.startsWith('/books')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/reading');
        break;
      case 1:
        GoRouter.of(context).go('/listening');
        break;
      case 2:
        GoRouter.of(context).go('/books');
        break;
    }
  }
}
