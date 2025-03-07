import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_article.dart';
import '../providers/language_provider.dart';
import '../providers/news_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsFeedWidget extends StatefulWidget {
  final String category;
  final int itemCount;
  final bool showHeader;
  final bool isScrollable;
  final double maxHeight;

  const NewsFeedWidget({
    super.key,
    this.category = '',
    this.itemCount = 5,
    this.showHeader = true,
    this.isScrollable = true,
    this.maxHeight = 400,
  });

  @override
  State<NewsFeedWidget> createState() => _NewsFeedWidgetState();
}

class _NewsFeedWidgetState extends State<NewsFeedWidget> {
  bool _isLoading = true;
  List<NewsArticle> _news = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      List<NewsArticle> news;

      if (widget.category.isEmpty) {
        news = await newsProvider.getBreakingNews();
      } else {
        news = await newsProvider.getNewsByCategory(widget.category);
      }

      if (mounted) {
        setState(() {
          _news = news.take(widget.itemCount).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load news: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.category.isEmpty
                      ? languageProvider.translate('latest_news')
                      : languageProvider
                          .translate('${widget.category.toLowerCase()}_news'),
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full news screen
                    // This would be implemented in a real app
                  },
                  child: Text(languageProvider.translate('view_all')),
                ),
              ],
            ),
          ),
        if (_isLoading)
          const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error.isNotEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchNews,
                    child: Text(languageProvider.translate('try_again')),
                  ),
                ],
              ),
            ),
          )
        else if (_news.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Text(languageProvider.translate('no_news')),
            ),
          )
        else
          Container(
            constraints: BoxConstraints(
              maxHeight:
                  widget.isScrollable ? widget.maxHeight : double.infinity,
            ),
            child: widget.isScrollable
                ? ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _news.length,
                    shrinkWrap: !widget.isScrollable,
                    physics: widget.isScrollable
                        ? const AlwaysScrollableScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _buildNewsItem(
                          _news[index], languageProvider, theme);
                    },
                  )
                : Column(
                    children: _news
                        .map((article) =>
                            _buildNewsItem(article, languageProvider, theme))
                        .toList(),
                  ),
          ),
      ],
    );
  }

  Widget _buildNewsItem(
      NewsArticle article, LanguageProvider languageProvider, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () async {
          // Open the article URL
          final url = Uri.parse(article.url);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12.0)),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    article.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article.source,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        timeago.format(article.publishedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
