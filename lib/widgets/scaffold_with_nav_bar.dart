import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Needed for more than 3 items
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Progress',
          ),
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
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/dashboard')) {
      return 1;
    }
    if (location.startsWith('/reading')) {
      return 2;
    }
    if (location.startsWith('/listening')) {
      return 3;
    }
    if (location.startsWith('/books')) {
      return 4;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    // Get the current location
    final String currentLocation = GoRouterState.of(context).uri.toString();
    String newLocation;

    // Determine the new location based on the index
    switch (index) {
      case 0:
        newLocation = '/home';
        break;
      case 1:
        newLocation = '/dashboard';
        break;
      case 2:
        newLocation = '/reading';
        break;
      case 3:
        newLocation = '/listening';
        break;
      case 4:
        newLocation = '/books';
        break;
      default:
        newLocation = '/home';
    }

    // Only navigate if we're going to a different location
    if (currentLocation != newLocation) {
      GoRouter.of(context).go(newLocation);
    }
  }
}
