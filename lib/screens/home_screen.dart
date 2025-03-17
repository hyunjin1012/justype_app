import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/achievement_banner.dart';
import '../services/progress_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProgressService _progressService = ProgressService();
  bool _needsRefresh = true;

  @override
  void initState() {
    super.initState();
    // Listen for progress updates
    _progressService.addListener(_onProgressUpdated);
    _loadProgress();
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    _progressService.removeListener(_onProgressUpdated);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_needsRefresh) {
      _loadProgress();
      _needsRefresh = false;
    }
  }

  // Called when progress is updated
  void _onProgressUpdated() {
    if (mounted) {
      setState(() {
        // Refresh UI with latest data
      });
    }
  }

  Future<void> _loadProgress() async {
    await _progressService.loadProgress();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Practice'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => GoRouter.of(context).push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily goal progress
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDailyGoalCard(context),
                ),

                // Show achievement banner if there are recent achievements
                if (_progressService.hasRecentAchievements())
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: AchievementBanner(
                      title: 'New Achievement!',
                      description: 'You\'ve earned a new achievement!',
                      icon: 'assets/animations/achievement.json',
                      backgroundColor: Colors.amber.shade100,
                      textColor: Colors.brown,
                    ),
                  ),

                // Practice modes section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Practice Modes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                // Practice mode cards
                _buildPracticeModeCards(context),

                // Recommended books section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Recommended Books',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),

                // Recommended books carousel
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: 5, // Example count
                    itemBuilder: (context, index) {
                      return _buildBookCard(context, index);
                    },
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyGoalCard(BuildContext context) {
    final progress = _progressService.getDailyGoalProgress();
    final goalText =
        '${_progressService.getTotalExercises()}/${_progressService.getDailyGoal()} exercises';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Goal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  goalText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            if (progress >= 1.0)
              const Text(
                'Goal completed! Great job!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                'Keep going!',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeModeCards(BuildContext context) {
    final List<Map<String, dynamic>> practiceModes = [
      {
        'title': 'Reading Practice',
        'description': 'Improve your reading skills',
        'icon': Icons.menu_book,
        'color': Colors.blue.shade100,
        'route': '/reading',
      },
      {
        'title': 'Listening Practice',
        'description': 'Enhance your listening comprehension',
        'icon': Icons.hearing,
        'color': Colors.green.shade100,
        'route': '/listening',
      },
      {
        'title': 'Browse Books',
        'description': 'Practice with classic literature',
        'icon': Icons.library_books,
        'color': Colors.purple.shade100,
        'route': '/books',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: practiceModes.length,
      itemBuilder: (context, index) {
        final mode = practiceModes[index];
        return GestureDetector(
          onTap: () => GoRouter.of(context).go(mode['route']),
          child: Card(
            elevation: 2,
            color: mode['color'],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(mode['icon'], size: 28),
                  const SizedBox(height: 4),
                  Text(
                    mode['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode['description'],
                    style: const TextStyle(fontSize: 11),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookCard(BuildContext context, int index) {
    // Example book data - in a real app, you would fetch this from a service
    final List<Map<String, dynamic>> recommendedBooks = [
      {
        'id': '1342', // Pride and Prejudice
        'title': 'Pride and Prejudice',
        'author': 'Jane Austen',
        'coverUrl':
            'https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg',
      },
      {
        'id': '84', // Frankenstein
        'title': 'Frankenstein',
        'author': 'Mary Shelley',
        'coverUrl':
            'https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg',
      },
      {
        'id': '11', // Alice's Adventures in Wonderland
        'title': 'Alice\'s Adventures in Wonderland',
        'author': 'Lewis Carroll',
        'coverUrl':
            'https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg',
      },
      {
        'id': '1661', // The Adventures of Sherlock Holmes
        'title': 'The Adventures of Sherlock Holmes',
        'author': 'Arthur Conan Doyle',
        'coverUrl':
            'https://www.gutenberg.org/cache/epub/1661/pg1661.cover.medium.jpg',
      },
      {
        'id': '2701', // Moby Dick
        'title': 'Moby Dick',
        'author': 'Herman Melville',
        'coverUrl':
            'https://www.gutenberg.org/cache/epub/2701/pg2701.cover.medium.jpg',
      },
    ];

    // If index is out of bounds, return an empty container
    if (index >= recommendedBooks.length) {
      return Container();
    }

    final book = recommendedBooks[index];

    return GestureDetector(
      onTap: () {
        // Navigate to book detail screen
        GoRouter.of(context).push('/book/${book['id']}');
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  book['coverUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.book, size: 40),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Book title
            Text(
              book['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Book author
            Text(
              book['author'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
