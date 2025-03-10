import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_article.dart';
import '../providers/language_provider.dart';
import '../services/news_service.dart';
import '../providers/news_provider.dart';
import '../config/env.dart';
import '../widgets/custom_bottom_nav.dart'; // Import the custom nav bar
import 'dart:async';

class NewsScreen extends StatefulWidget {
  final String? stockSymbol;
  final String? stockName;

  const NewsScreen({
    super.key,
    this.stockSymbol,
    this.stockName,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with WidgetsBindingObserver {
  final NewsService _newsService = NewsService();
  late Future<List<NewsArticle>> _newsFuture;
  String _selectedCategory = 'business';
  final List<String> _categories = [
    'business',
    'technology',
    'finance',
    'markets',
    'economy'
  ];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNews();

    // Set up automatic refresh every 5 minutes when the app is active
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        _loadNews();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh news when app returns to foreground
    if (state == AppLifecycleState.resumed) {
      _loadNews();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadNews() async {
    if (!mounted) return;

    setState(() {
      if (widget.stockSymbol != null) {
        _newsFuture = _newsService.getStockNews(widget.stockSymbol!);
      } else if (_isSearching && _searchController.text.isNotEmpty) {
        _newsFuture = _newsService.searchNews(_searchController.text);
      } else {
        // Load appropriate news based on the selected tab
        if (_currentTabIndex == 0) {
          _newsFuture = _newsService.fetchAndCacheNews(); // General news
        } else {
          _newsFuture = _newsService.getMarketNews(); // Market news
        }
      }
    });

    // Also update the provider for other screens that might need news data
    if (mounted) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      await newsProvider.fetchNews(category: _selectedCategory);
    }
  }

  // Launch URL safely
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open article: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: lang.translate('search_news'),
                    hintStyle: TextStyle(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _newsFuture = _newsService.searchNews(value);
                      });
                    }
                  },
                )
              : Text(
                  widget.stockSymbol != null
                      ? '${widget.stockName ?? widget.stockSymbol} ${lang.translate('news')}'
                      : lang.translate('news'),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _loadNews();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadNews,
              tooltip: lang.translate('refresh'),
            ),
          ],
          bottom: TabBar(
            onTap: (index) {
              setState(() {
                _currentTabIndex = index;
                _loadNews();
              });
            },
            tabs: [
              Tab(text: lang.translate('general_news')),
              Tab(text: lang.translate('market_news')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // General news tab
            Column(
              children: [
                if (widget.stockSymbol == null) _buildCategoryFilter(),
                Expanded(
                  child: _buildNewsList(_newsFuture),
                ),
              ],
            ),
            // Market news tab
            FutureBuilder<List<NewsArticle>>(
              future: _newsService.getMarketNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return _buildErrorWidget(
                      snapshot.error.toString(), theme, lang);
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyNewsWidget(theme, lang);
                }
                return _buildNewsListView(snapshot.data!, theme);
              },
            ),
          ],
        ),
        // Replace standard BottomNavigationBar with our CustomBottomNavBar
        bottomNavigationBar: widget.stockSymbol == null
            ? CustomBottomNavBar(
                currentIndex:
                    0, // News is shown from different places, default to home
                onTap: (index) {
                  final routes = ['/home', '/market', '/portfolio', '/profile'];
                  Navigator.pushReplacementNamed(context, routes[index]);
                },
              )
            : null,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final lang = Provider.of<LanguageProvider>(context);
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(lang.translate(category)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category;
                    _loadNews();
                  });
                }
              },
              labelStyle: GoogleFonts.spaceGrotesk(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNewsList(Future<List<NewsArticle>> newsFuture) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return FutureBuilder<List<NewsArticle>>(
      future: newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString(), theme, lang);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyNewsWidget(theme, lang);
        }

        return _buildNewsListView(snapshot.data!, theme);
      },
    );
  }

  Widget _buildErrorWidget(
      String error, ThemeData theme, LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            lang.translate('error_loading_news'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            Env.useRealNewsData
                ? lang.translate('check_connection')
                : lang.translate('using_mock_data'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNews,
            child: Text(lang.translate('try_again')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNewsWidget(ThemeData theme, LanguageProvider lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 60,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            lang.translate('no_news_available'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            lang.translate('try_different_category'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsListView(List<NewsArticle> news, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadNews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: news.length,
        itemBuilder: (context, index) {
          return _buildNewsCard(news[index], index);
        },
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article, int index) {
    final theme = Theme.of(context);
    final formattedDate =
        DateFormat.yMMMd().add_jm().format(article.publishedAt);

    return FadeInUp(
      duration: Duration(milliseconds: 300 + (index * 50)),
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            _showArticleDetail(article);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Generate a stable but different fallback image for each article
                      final fallbackUrl =
                          'https://picsum.photos/seed/${article.title.hashCode}/800/400';
                      return Image.network(
                        fallbackUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            height: 180,
                            width: double.infinity,
                            child: Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        height: 180,
                        width: double.infinity,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.description,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        height: 1.4,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.public,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.source,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
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
      ),
    );
  }

  void _showArticleDetail(NewsArticle article) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final formattedDate =
        DateFormat.yMMMd().add_jm().format(article.publishedAt);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              lang.translate('article'),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.imageUrl.isNotEmpty)
                  SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: Image.network(
                      article.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          height: 240,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 60,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.public,
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            article.source,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Text(
                        article.description,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          height: 1.6,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (article.url.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _launchURL(article.url),
                          icon: const Icon(Icons.open_in_new),
                          label: Text(lang.translate('read_full_article')),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: theme.colorScheme.onPrimary,
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
