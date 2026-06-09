class BookmarkEntry {
  final String bookId;
  final String title;
  final List<String> pathSegments;
  final int page;
  final int total;

  const BookmarkEntry({
    required this.bookId,
    required this.title,
    required this.pathSegments,
    required this.page,
    required this.total,
  });

  factory BookmarkEntry.fromJson(Map<String, dynamic> json) => BookmarkEntry(
        bookId: json['bookId'] as String,
        title: json['title'] as String,
        pathSegments: List<String>.from(json['pathSegments'] as List),
        page: json['page'] as int,
        total: json['total'] as int,
      );

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'title': title,
        'pathSegments': pathSegments,
        'page': page,
        'total': total,
      };
}
