import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../data/ethio_data.dart';
import '../utils/ethiopian_utils.dart';
import '../providers/language_provider.dart';
import '../providers/market_provider.dart';
import '../models/asset.dart';
import 'stock_detail_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/news_feed_widget.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedSector = 'All';
  String _searchQuery = '';
  late Timer _marketStatusTimer;
  bool _isMarketOpen = false;
  bool _isLoading = true;
  int _selectedTimeRange = 1; // 0: 1D, 1: 1W, 2: 1M, 3: 3M, 4: 1Y, 5: ALL
  int _currentTabIndex =
      0; // 0: All, 1: Ethiopian, 2: International, 3: Favorites

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Updated to 4 tabs
    _updateMarketStatus();
    _marketStatusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateMarketStatus(),
    );

    // Load market data
    _initData();

    // Listen for tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  Future<void> _initData() async {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      await marketProvider.fetchMarketData();
    } catch (e) {
      // Handle error
      debugPrint('Error fetching market data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _marketStatusTimer.cancel();
    super.dispose();
  }

  void _updateMarketStatus() {
    final marketProvider = Provider.of<MarketProvider>(context, listen: false);
    setState(() {
      _isMarketOpen = marketProvider.isMarketOpen;
    });
  }

  List<Asset> _getFilteredAssets(List<Asset> assets) {
    return assets.where((asset) {
      final matchesSearch =
          asset.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              asset.symbol.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSector =
          _selectedSector == 'All' || asset.sector == _selectedSector;
      return matchesSearch && matchesSector;
    }).toList();
  }

  // Market summary data for a given list of assets
  Map<String, dynamic> _getMarketSummary(List<Asset> assets) {
    double totalVolume = 0;
    int gainers = 0;
    int losers = 0;

    for (var asset in assets) {
      totalVolume += asset.volume;
      if (asset.change > 0) {
        gainers++;
      } else if (asset.change < 0) {
        losers++;
      }
    }

    return {
      'totalVolume': totalVolume,
      'gainers': gainers,
      'losers': losers,
      'unchanged': assets.length - gainers - losers,
    };
  }

  Widget _buildSearchBar(ThemeData theme, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(33),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: lang.translate('search_stocks'),
            hintStyle: GoogleFonts.spaceGrotesk(
              color: theme.hintColor,
            ),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildSectorFilter(LanguageProvider lang) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('All', lang.translate('all_sectors')),
          const SizedBox(width: 8),
          ...EthioData.getSectors().map((sector) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                    sector, lang.translate(sector.toLowerCase())),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String sector, String label) {
    final theme = Theme.of(context);
    final isSelected = sector == _selectedSector;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primary.withAlpha(51)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.grey.withAlpha(77),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedSector = sector),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketSummary(
      ThemeData theme, LanguageProvider lang, List<Asset> assets) {
    final summary = _getMarketSummary(assets);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGradient.last.withValues(alpha:0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.translate('market_summary'),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              _buildTimeRangeSelector(theme),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                icon: Icons.arrow_upward,
                label: lang.translate('gainers'),
                value: '${summary['gainers']}',
                valueColor: AppTheme.bullish,
                bgColor: Colors.white.withValues(alpha:0.15),
              ),
              _buildSummaryItem(
                icon: Icons.arrow_downward,
                label: lang.translate('losers'),
                value: '${summary['losers']}',
                valueColor: AppTheme.bearish,
                bgColor: Colors.white.withValues(alpha:0.15),
              ),
              _buildSummaryItem(
                icon: Icons.show_chart,
                label: lang.translate('volume'),
                value:
                    '${(summary['totalVolume'] / 1000000).toStringAsFixed(1)}M',
                valueColor: Colors.white,
                bgColor: Colors.white.withValues(alpha:0.15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: valueColor, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withAlpha(204),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    final ranges = ['1D', '1W', '1M', '3M', '1Y', 'ALL'];

    return Container(
      height: 26,
      width: 180, // Fixed width to prevent overflow
      decoration: BoxDecoration(
        color: Colors.white
            .withAlpha(38), // Using withAlpha instead of withOpacity
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(ranges.length, (index) {
          final isSelected = index == _selectedTimeRange;

          return Expanded(
            // Make each item take equal width
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeRange = index;
                  // Add functionality for range change
                  _updateDataForTimeRange(ranges[index]);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center, // Center text
                child: Text(
                  ranges[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppTheme.primaryGradient.first
                        : Colors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Add time range functionality
  void _updateDataForTimeRange(String range) {
    // In a real app, this would fetch data for the selected time range
    // For this demo, we'll just simulate a data update
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _isLoading = false;
        // Here you would update the market data based on the selected range
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
    final marketProvider = Provider.of<MarketProvider>(context);

    // Get assets based on current tab
    List<Asset> currentAssets;
    switch (_currentTabIndex) {
      case 0: // All
        currentAssets = [
          ...marketProvider.ethiopianAssets,
          ...marketProvider.internationalAssets
        ];
        break;
      case 1: // Ethiopian
        currentAssets = marketProvider.ethiopianAssets;
        break;
      case 2: // International
        currentAssets = marketProvider.internationalAssets;
        break;
      case 3: // Favorites
        currentAssets = marketProvider.favoriteAssets;
        break;
      default:
        currentAssets = [
          ...marketProvider.ethiopianAssets,
          ...marketProvider.internationalAssets
        ];
    }

    // Apply search and sector filters
    final filteredAssets = _getFilteredAssets(currentAssets);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, lang),
            _buildTabBar(theme, lang),
            _buildMarketStatusBanner(theme, lang),
            _buildMarketSummary(theme, lang, currentAssets),
            _buildSearchBar(theme, lang),
            _buildSectorFilter(lang),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredAssets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color:
                                    theme.colorScheme.primary.withValues(alpha:0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentTabIndex == 3 &&
                                        marketProvider.favoriteAssets.isEmpty
                                    ? lang.translate('no_favorites')
                                    : lang.translate('no_search_results'),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha:0.7),
                                ),
                              ),
                              if (_currentTabIndex == 3 &&
                                  marketProvider.favoriteAssets.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    lang.translate('add_assets_to_favorites'),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha:0.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _initData,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredAssets.length,
                            itemBuilder: (context, index) {
                              return _buildAssetCard(
                                  filteredAssets[index], theme, lang);
                            },
                          ),
                        ),
            ),
            // News section for this market
            if (_currentTabIndex != 3) // Don't show news in favorites tab
              Container(
                height: 300,
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currentTabIndex == 1
                                  ? lang.translate('ethiopian_news')
                                  : lang.translate('market_news'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: NewsFeedWidget(
                          category: _currentTabIndex == 1
                              ? 'ethiopian'
                              : 'international',
                          itemCount: 3,
                          maxHeight: 250,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, LanguageProvider lang) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha:0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.primary,
        ),
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurface,
        labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(),
        tabs: [
          Tab(text: lang.translate('all')),
          Tab(text: lang.translate('ethiopian')),
          Tab(text: lang.translate('international')),
          const Tab(
            icon: Icon(Icons.star),
            iconMargin: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lang.translate('market'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none,
                    color: theme.colorScheme.primary),
                onPressed: () => _showNotifications(context),
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
                onPressed: () => _showOptionsMenu(context),
                tooltip: 'More options',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show notifications
  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.bullish,
                radius: 20,
                child: Icon(Icons.trending_up, color: Colors.white),
              ),
              title: const Text('Market Alert'),
              subtitle: const Text('ESE index up by 2.3% today'),
              trailing:
                  Text('2h ago', style: TextStyle(color: Colors.grey[600])),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.bearish,
                radius: 20,
                child: Icon(Icons.trending_down, color: Colors.white),
              ),
              title: const Text('Price Alert'),
              subtitle: const Text('COOP down by 5% in the last hour'),
              trailing:
                  Text('5h ago', style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }

  // Show options menu
  void _showOptionsMenu(BuildContext context) {
    final theme = Theme.of(context);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          MediaQuery.of(context).size.width - 40, 80, 20, 0),
      items: [
        PopupMenuItem(
          value: 'filter',
          child: Row(
            children: [
              Icon(Icons.filter_list, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Advanced Filters'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Refresh Data'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Market Settings'),
            ],
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value == 'refresh') {
        setState(() {
          _isLoading = true;
        });
        _initData();
      } else if (value == 'filter') {
        // Show advanced filter dialog
      } else if (value == 'settings') {
        // Navigate to market settings
      }
    });
  }

  Widget _buildMarketStatusBanner(ThemeData theme, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isMarketOpen
              ? AppTheme.successGradient
              : [AppTheme.bearish.withAlpha(179), AppTheme.bearish],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _isMarketOpen
                ? AppTheme.successGradient.last.withAlpha(76)
                : AppTheme.bearish.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(128),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isMarketOpen
                ? lang.translate('market_open')
                : lang.translate('market_closed'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              EthiopianMarketHours.getMarketStatus(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(Asset asset, ThemeData theme, LanguageProvider lang) {
    final isPositive = asset.change >= 0;
    final changeColor = isPositive ? AppTheme.bullish : AppTheme.bearish;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StockDetailScreen(asset: asset),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha:0.7),
                      theme.colorScheme.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    asset.symbol.substring(0, 1),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          asset.symbol,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (asset.isFavorite)
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      asset.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          asset.sector == 'Bank' || asset.sector == 'Banking'
                              ? Icons.account_balance
                              : asset.sector == 'Technology'
                                  ? Icons.computer
                                  : asset.sector == 'Manufacturing'
                                      ? Icons.precision_manufacturing
                                      : Icons.business,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          asset.sector,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    asset.formattedPrice,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: changeColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          asset.formattedChangePercent,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vol: ${(asset.volume / 1000).round()}K',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Add quick favorite toggle button
              IconButton(
                icon: Icon(
                  asset.isFavorite ? Icons.star : Icons.star_border,
                  color: asset.isFavorite ? Colors.amber : Colors.grey,
                ),
                onPressed: () {
                  final marketProvider =
                      Provider.of<MarketProvider>(context, listen: false);
                  marketProvider.toggleFavorite(asset);
                },
                iconSize: 20,
                splashRadius: 20,
                tooltip: asset.isFavorite
                    ? lang.translate('remove_from_favorites')
                    : lang.translate('add_to_watchlist'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
