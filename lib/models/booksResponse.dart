class BooksResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<BookItem> results;

  BooksResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory BooksResponse.fromJson(Map<String, dynamic> json) {
    return BooksResponse(
      count: json['count'],
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List)
          .map((item) => BookItem.fromJson(item))
          .toList(),
    );
  }
}

class BookItem {
  final int id;
  final String title;
  final List<Author> authors;
  final List<String> subjects;
  final List<String> bookshelves;
  final List<String> languages;
  final bool copyright;
  final String? mediaType;
  final Formats formats;
  final int downloadCount;

  BookItem({
    required this.id,
    required this.title,
    required this.authors,
    required this.subjects,
    required this.bookshelves,
    required this.languages,
    required this.copyright,
    this.mediaType,
    required this.formats,
    required this.downloadCount,
  });

  factory BookItem.fromJson(Map<String, dynamic> json) {
    return BookItem(
      id: json['id'],
      title: json['title'],
      authors: (json['authors'] as List)
          .map((author) => Author.fromJson(author))
          .toList(),
      subjects: List<String>.from(json['subjects']),
      bookshelves: List<String>.from(json['bookshelves']),
      languages: List<String>.from(json['languages']),
      copyright: json['copyright'] ?? false,
      mediaType: json['media_type'],
      formats: Formats.fromJson(json['formats']),
      downloadCount: json['download_count'],
    );
  }
}

class Author {
  final String name;
  final int? birthYear;
  final int? deathYear;

  Author({
    required this.name,
    this.birthYear,
    this.deathYear,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      name: json['name'],
      birthYear: json['birth_year'],
      deathYear: json['death_year'],
    );
  }
}

class Formats {
  final String? textPlain;
  final String? textHtml;
  final String? epub;
  final String? pdf;
  final String? imagejpeg;

  Formats({
    this.textPlain,
    this.textHtml,
    this.epub,
    this.pdf,
    this.imagejpeg,
  });

  factory Formats.fromJson(Map<String, dynamic> json) {
    return Formats(
      textPlain: json['text/plain; charset=utf-8'],
      textHtml: json['text/html; charset=utf-8'],
      epub: json['application/epub+zip'],
      pdf: json['application/pdf'],
      imagejpeg: json['image/jpeg'],
    );
  }
}
