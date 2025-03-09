class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String source;
  final DateTime publishedAt;

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  // Create from JSON (for API responses)
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No title',
      description: json['description'] ?? 'No description',
      url: json['url'] ?? '',
      imageUrl: json['urlToImage'] ?? json['image'] ?? '',
      source: json['source'] is String
          ? json['source']
          : json['source'] is Map
              ? json['source']['name'] ?? 'Unknown'
              : 'Unknown',
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt']) ?? DateTime.now()
          : json['datetime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(json['datetime'] * 1000)
              : DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': imageUrl,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
    };
  }
}
