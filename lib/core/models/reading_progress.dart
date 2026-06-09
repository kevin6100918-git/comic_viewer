class ReadingProgress {
  final String bookId;
  final String title;
  final List<String> pathSegments;
  final int page;
  final int total;
  final int updatedAt;

  const ReadingProgress({
    required this.bookId,
    required this.title,
    required this.pathSegments,
    required this.page,
    required this.total,
    required this.updatedAt,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) => ReadingProgress(
        bookId: json['bookId'] as String,
        title: json['title'] as String,
        pathSegments: List<String>.from(json['pathSegments'] as List),
        page: json['page'] as int,
        total: json['total'] as int,
        updatedAt: json['updatedAt'] as int,
      );

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'title': title,
        'pathSegments': pathSegments,
        'page': page,
        'total': total,
        'updatedAt': updatedAt,
      };

  ReadingProgress copyWith({int? page, int? total, int? updatedAt}) =>
      ReadingProgress(
        bookId: bookId,
        title: title,
        pathSegments: pathSegments,
        page: page ?? this.page,
        total: total ?? this.total,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
