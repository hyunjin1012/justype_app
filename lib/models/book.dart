class Book {
  final String id;
  final String title;
  final String author;
  final String content;
  final List<String> subjects;
  final String displayStyle;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    this.subjects = const [],
    this.displayStyle = 'prose',
  });
}
