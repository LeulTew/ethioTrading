class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String source;
  final DateTime publishedAt;
  final List<String> categories;
  final bool isFeatured;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
    this.categories = const [],
    this.isFeatured = false,
  });

  // Create news article from JSON
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      source: json['source'] ?? '',
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'])
          : DateTime.now(),
      categories: List<String>.from(json['categories'] ?? []),
      isFeatured: json['isFeatured'] ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'imageUrl': imageUrl,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
      'categories': categories,
      'isFeatured': isFeatured,
    };
  }

  // Create a copy with modifications
  NewsArticle copyWith({
    String? title,
    String? description,
    String? url,
    String? imageUrl,
    String? source,
    DateTime? publishedAt,
    List<String>? categories,
    bool? isFeatured,
  }) {
    return NewsArticle(
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      source: source ?? this.source,
      publishedAt: publishedAt ?? this.publishedAt,
      categories: categories ?? this.categories,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }
}
