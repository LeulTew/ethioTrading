import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/language_provider.dart';
import '../providers/news_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsFeedWidget extends StatefulWidget {
  final String category;
  final int itemCount;
  final double? maxHeight;
  final bool showFullList;

  const NewsFeedWidget({
    super.key,
    required this.category,
    this.itemCount = 5,
    this.maxHeight,
    this.showFullList = false,
  });

  @override
  State<NewsFeedWidget> createState() => _NewsFeedWidgetState();
}

class _NewsFeedWidgetState extends State<NewsFeedWidget> {
  @override
  void initState() {
    super.initState();

    // Fetch news when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      newsProvider.fetchNewsForCategory(category: widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);

    // Get news for the specified category
    final news = newsProvider.getNewsByCategoryFromApi(widget.category);
    final isLoading = newsProvider.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageProvider.translate(widget.category == 'ethiopian'
                    ? 'ethiopian_news'
                    : 'market_news'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full news screen
                  Navigator.pushNamed(
                    context,
                    '/news',
                    arguments: widget.category,
                  );
                },
                child: Text(languageProvider.translate('view_all')),
              ),
            ],
          ),
        ),

        // News list
        Container(
          constraints: widget.maxHeight != null
              ? BoxConstraints(maxHeight: widget.maxHeight!)
              : null,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : news.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          languageProvider.translate('no_news_available'),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : widget.showFullList
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: widget.maxHeight != null
                              ? const ClampingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          itemCount: news.length,
                          itemBuilder: (context, index) {
                            final article = news[index];
                            return _buildNewsCard(
                              context,
                              article,
                              languageProvider,
                            );
                          },
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: widget.maxHeight != null
                              ? const ClampingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          itemCount: news.length > widget.itemCount
                              ? widget.itemCount
                              : news.length,
                          itemBuilder: (context, index) {
                            final article = news[index];
                            return _buildNewsCard(
                              context,
                              article,
                              languageProvider,
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(
    BuildContext context,
    Map<String, dynamic> article,
    LanguageProvider languageProvider,
  ) {
    final theme = Theme.of(context);

    // Parse published date
    DateTime? publishedDate;
    try {
      publishedDate = DateTime.parse(article['publishedAt']);
    } catch (e) {
      // Use current date if parsing fails
      publishedDate = DateTime.now();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _openArticle(article['url']),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image
            if (article['urlToImage'] != null &&
                article['urlToImage'].isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(
                  article['urlToImage'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.newspaper, size: 50, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        article['source'] ?? 'News',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Article content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source and date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article['source'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeago.format(publishedDate),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    article['title'] ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (article['description'] != null)
                    Text(
                      article['description'],
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),

                  // Read more button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _openArticle(article['url']),
                      child: Text(languageProvider.translate('read_more')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Open article in browser
  Future<void> _openArticle(String? url) async {
    if (url == null || url.isEmpty) return;

    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open article')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening article: ${e.toString()}')),
      );
    }
  }
}
