import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../data/ethio_data.dart';
import '../providers/language_provider.dart';
import '../providers/market_provider.dart';
import '../widgets/market_list_widget.dart';
import '../widgets/news_feed_widget.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../models/asset.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> ethioMarketData = [];
  final String _selectedSector = 'All';
  late Timer _marketStatusTimer;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0;

  // Market filter options
  final List<String> _filterOptions = [
    'All',
    'Gainers',
    'Losers',
    'Most Active'
  ];

  @override
  void initState() {
    super.initState();
    _initData();
    _tabController = TabController(length: 2, vsync: this);
    _updateMarketStatus();
    _marketStatusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateMarketStatus(),
    );

    // Initialize market data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final marketProvider =
          Provider.of<MarketProvider>(context, listen: false);
      marketProvider.fetchMarketData();
    });
  }

  Future<void> _initData() async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay
    setState(() {
      ethioMarketData = EthioData.generateMockEthioMarketData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _marketStatusTimer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _updateMarketStatus() {
    // This method is now empty as the _isMarketOpen and _isLoading fields are removed
  }

  List<Map<String, dynamic>> get filteredData {
    return ethioMarketData.where((data) {
      final matchesSearch = data['name']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          data['symbol']
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesSector =
          _selectedSector == 'All' || data['sector'] == _selectedSector;
      return matchesSearch && matchesSector;
    }).toList();
  }

  // Market summary data
  Map<String, dynamic> get marketSummary {
    double totalVolume = 0;
    double prevDayVolume = 0;
    int gainers = 0;
    int losers = 0;

    for (var stock in ethioMarketData) {
      totalVolume += (stock['volume'] as num).toDouble();
      prevDayVolume += (stock['prevDayVolume'] as num? ?? 0).toDouble();
      if ((stock['change'] as double) > 0) {
        gainers++;
      } else if ((stock['change'] as double) < 0) {
        losers++;
      }
    }

    double volumeChange = prevDayVolume > 0
        ? ((totalVolume - prevDayVolume) / prevDayVolume) * 100
        : 0;

    return {
      'volume': totalVolume.toStringAsFixed(2),
      'volumeChange': volumeChange.toStringAsFixed(1),
      'gainers': gainers,
      'losers': losers,
      'unchanged': ethioMarketData.length - gainers - losers,
      'marketBreadth': gainers / (gainers + losers)
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
    final marketProvider = Provider.of<MarketProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: lang.translate('search_markets'),
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 153)), // 0.6 * 255 = 153
                ),
                style: TextStyle(color: theme.colorScheme.onSurface),
                onChanged: (value) {
                  setState(() {
                    marketProvider.searchAssets(value);
                  });
                },
                autofocus: true,
              )
            : Text(lang.translate('markets')),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  marketProvider.clearSearch();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              marketProvider.fetchMarketData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: lang.translate('ethiopian_market')),
            Tab(text: lang.translate('international_market')),
          ],
          indicatorSize: TabBarIndicatorSize.label,
          indicatorWeight: 3,
        ),
      ),
      body: Column(
        children: [
          // Market status indicator
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            color: theme.colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: marketProvider.isMarketOpen
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      marketProvider.isMarketOpen
                          ? lang.translate('market_open')
                          : lang.translate('market_closed'),
                      style: TextStyle(
                        color: marketProvider.isMarketOpen
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  marketProvider.lastUpdated != null
                      ? '${lang.translate('last_updated')}: ${marketProvider.formattedLastUpdated}'
                      : '',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Filter options
          if (!_isSearching)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filterOptions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                          lang.translate(_filterOptions[index].toLowerCase())),
                      selected: _selectedFilterIndex == index,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          // Market data
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Ethiopian Market Tab
                _buildMarketTab(
                  marketProvider: marketProvider,
                  languageProvider: lang,
                  isEthiopian: true,
                ),

                // International Market Tab
                _buildMarketTab(
                  marketProvider: marketProvider,
                  languageProvider: lang,
                  isEthiopian: false,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Market is selected
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: lang.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            label: lang.translate('market'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: lang.translate('portfolio'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: lang.translate('profile'),
          ),
        ],
        onTap: (index) {
          if (index != 1) {
            // Navigate to the appropriate screen
            final routes = ['/home', '/market', '/portfolio', '/profile'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  Widget _buildMarketTab({
    required MarketProvider marketProvider,
    required LanguageProvider languageProvider,
    required bool isEthiopian,
  }) {
    final assets = isEthiopian
        ? marketProvider.ethiopianAssets
        : marketProvider.internationalAssets;

    // Apply filters based on selected filter option
    List<Asset> filteredAssets = [];

    if (_isSearching) {
      filteredAssets = marketProvider.searchResults
          .where((asset) =>
              (isEthiopian && asset.sector == 'Ethiopian') ||
              (!isEthiopian && asset.sector == 'International'))
          .toList();
    } else {
      switch (_selectedFilterIndex) {
        case 0: // All
          filteredAssets = List<Asset>.from(assets);
          break;
        case 1: // Gainers
          filteredAssets = assets.where((asset) => asset.change > 0).toList();
          break;
        case 2: // Losers
          filteredAssets = assets.where((asset) => asset.change < 0).toList();
          break;
        case 3: // Most Active
          filteredAssets = List<Asset>.from(assets)
            ..sort((a, b) => b.volume.compareTo(a.volume));
          break;
      }
    }

    return RefreshIndicator(
      onRefresh: () => marketProvider.fetchMarketData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Market summary card
            _buildMarketSummaryCard(
              marketProvider: marketProvider,
              languageProvider: languageProvider,
              isEthiopian: isEthiopian,
            ),

            // Market statistics
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        title: languageProvider.translate('gainers'),
                        value: marketProvider
                            .getGainersCount(isEthiopian)
                            .toString(),
                        color: Colors.green,
                      ),
                      _buildStatColumn(
                        title: languageProvider.translate('losers'),
                        value: marketProvider
                            .getLosersCount(isEthiopian)
                            .toString(),
                        color: Colors.red,
                      ),
                      _buildStatColumn(
                        title: languageProvider.translate('volume'),
                        value: NumberFormat.compact()
                            .format(marketProvider.getTotalVolume(isEthiopian)),
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Market list
            Container(
              height: filteredAssets.isEmpty ? 200 : 300,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              languageProvider.translate('tradable_assets'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigate to a full list view
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      appBar: AppBar(
                                        title: Text(
                                          isEthiopian
                                              ? languageProvider
                                                  .translate('ethiopian_market')
                                              : languageProvider.translate(
                                                  'international_market'),
                                        ),
                                      ),
                                      body: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: MarketListWidget(
                                          assets: filteredAssets,
                                          onAssetTap: (asset) {
                                            Navigator.pushNamed(
                                              context,
                                              '/asset_details',
                                              arguments: asset,
                                            );
                                          },
                                          showFullList: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child:
                                  Text(languageProvider.translate('view_all')),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: marketProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filteredAssets.isEmpty
                                ? Center(
                                    child: Text(
                                      _isSearching
                                          ? languageProvider
                                              .translate('no_search_results')
                                          : languageProvider
                                              .translate('no_assets_available'),
                                    ),
                                  )
                                : MarketListWidget(
                                    assets: filteredAssets,
                                    onAssetTap: (asset) {
                                      // Navigate to asset details
                                      Navigator.pushNamed(
                                        context,
                                        '/asset_details',
                                        arguments: asset,
                                      );
                                    },
                                    maxItems: 5,
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // News section for this market
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
                            languageProvider.translate('market_news'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to a full news view
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(
                                      title: Text(
                                        languageProvider
                                            .translate('market_news'),
                                      ),
                                    ),
                                    body: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: NewsFeedWidget(
                                        category: isEthiopian
                                            ? 'ethiopian'
                                            : 'international',
                                        showFullList: true,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              languageProvider.translate('view_all_news'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: NewsFeedWidget(
                        category: isEthiopian ? 'ethiopian' : 'international',
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

  Widget _buildMarketSummaryCard({
    required MarketProvider marketProvider,
    required LanguageProvider languageProvider,
    required bool isEthiopian,
  }) {
    final assets = isEthiopian
        ? marketProvider.ethiopianAssets
        : marketProvider.internationalAssets;

    if (assets.isEmpty) {
      return const SizedBox.shrink();
    }

    // Generate random data for the chart
    final List<FlSpot> spots = List.generate(
      20,
      (i) => FlSpot(
        i.toDouble(),
        100 + math.Random().nextInt(50).toDouble() + (i * 2),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEthiopian
                    ? languageProvider.translate('ethiopian_market_index')
                    : languageProvider.translate('international_market_index'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    isEthiopian ? 'ESX' : 'MSCI',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEthiopian ? '1,250.45' : '3,762.85',
                    style: const TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          Colors.green.withValues(alpha: 51), // 0.2 * 255 = 51
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '+2.34%',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withValues(
                              alpha: 26), // 0.1 * 255 = 25.5, rounded to 26
                        ),
                      ),
                    ],
                    minY: spots.map((e) => e.y).reduce(math.min) * 0.95,
                    maxY: spots.map((e) => e.y).reduce(math.max) * 1.05,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
